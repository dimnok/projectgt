import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/contract_act_line.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Убирает суффикс «(в т.ч. перенос с прошлых ВОР: …)» из наименования (legacy в БД).
String ks2ActLineDisplayName(String raw) {
  final stripped = raw.trim().replaceFirst(
    RegExp(r'\s*\(в т\.ч\. перенос с прошлых ВОР:[^)]*\)\s*$'),
    '',
  );
  final result = stripped.trim();
  return result.isEmpty ? '—' : result;
}

/// Строка таблицы работ КС-2 (сохранённый акт или превью по ВОР).
class Ks2ActLineRow {
  /// Создаёт строку таблицы.
  const Ks2ActLineRow({
    required this.rowKey,
    required this.sectionTitle,
    required this.estimateNumber,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.price,
    this.amount,
    this.backlogQuantity = 0,
  });

  /// Уникальный ключ строки (id акта или синтетический для превью).
  final String rowKey;

  /// Раздел сметы (`estimate_title` / `sectionTitle`).
  final String sectionTitle;

  /// Номер позиции в смете.
  final String estimateNumber;

  /// Наименование работ.
  final String name;

  /// Единица измерения.
  final String unit;

  /// Количество (базовое / из превью).
  final double quantity;

  /// Цена за единицу.
  final double price;

  /// Сумма строки; если `null` — `quantity * price`.
  final double? amount;

  /// Перенос с прошлых ВОР (только для сохранённого акта).
  final double backlogQuantity;

  /// Сумма для отображения в режиме просмотра.
  double get displayAmount => amount ?? quantity * price;
}

/// Финансовые итоги в подвале таблицы (сумма, НДС, к оплате).
class Ks2ActLinesTableFinancialFooter {
  /// Создаёт блок итогов.
  const Ks2ActLinesTableFinancialFooter({
    required this.amount,
    required this.vatAmount,
    required this.totalToPay,
  });

  /// Сумма акта без начисляемого сверху НДС.
  final double amount;

  /// НДС.
  final double vatAmount;

  /// К оплате с учётом удержаний.
  final double totalToPay;
}

/// Параметры редактирования количества в [Ks2ActLinesTable].
class Ks2ActLinesTableEditConfig {
  /// Создаёт конфигурацию редактирования.
  const Ks2ActLinesTableEditConfig({
    required this.qtyControllers,
    required this.onQtyChanged,
    this.onDelete,
    this.invalidRowKeys = const {},
    this.modifiedRowKeys = const {},
    this.onQtyBlur,
  });

  /// Контроллеры поля «Кол-во» по [Ks2ActLineRow.rowKey].
  final Map<String, TextEditingController> qtyControllers;

  /// После изменения количества (пересчёт итогов снаружи).
  final VoidCallback onQtyChanged;

  /// Удаление строки (колонка корзины).
  final void Function(Ks2ActLineRow row)? onDelete;

  /// Строки с невалидным количеством (подсветка после blur).
  final Set<String> invalidRowKeys;

  /// Строки с изменённым количеством относительно БД.
  final Set<String> modifiedRowKeys;

  /// Проверка количества при потере фокуса.
  final void Function(Ks2ActLineRow row)? onQtyBlur;
}

enum _Ks2ListEntryKind { sectionHeader, dataRow }

class _Ks2ListEntry {
  const _Ks2ListEntry.sectionHeader(
    this.sectionKey,
    this.sectionTitle,
    this.sectionTotal,
  ) : kind = _Ks2ListEntryKind.sectionHeader,
      row = null;

  const _Ks2ListEntry.dataRow(this.row, this.sectionKey)
    : kind = _Ks2ListEntryKind.dataRow,
      sectionTitle = null,
      sectionTotal = null;

  final _Ks2ListEntryKind kind;
  final String? sectionKey;
  final String? sectionTitle;
  final Ks2ActLineRow? row;
  final double? sectionTotal;
}

/// Таблица позиций КС-2: виртуальный список, лёгкая вёрстка.
///
/// Количество редактируется по нажатию на ячейку (одно поле ввода за раз).
/// Используется в форме акта и в превью по ВОР.
class Ks2ActLinesTable extends StatefulWidget {
  /// Создаёт таблицу работ КС-2.
  const Ks2ActLinesTable({
    super.key,
    required this.rows,
    required this.totalAmount,
    this.financialFooter,
    this.edit,
    this.emptyMessage,
  });

  /// Строки таблицы (порядок как в акте / API).
  final List<Ks2ActLineRow> rows;

  /// Итоговая сумма строк (база для подвала).
  final double totalAmount;

  /// Развёрнутый подвал: сумма, НДС, к оплате. Если `null` — одна строка «Итого».
  final Ks2ActLinesTableFinancialFooter? financialFooter;

  /// Редактирование количества и удаление; `null` — только просмотр.
  final Ks2ActLinesTableEditConfig? edit;

  /// Сообщение при пустом [rows] (если `null` — стандартное).
  final String? emptyMessage;

  /// Парсит количество из текстового поля.
  static double? parseQty(String raw) {
    final t = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v < 0) return null;
    return v;
  }

  /// Форматирует количество для поля ввода.
  static String formatQtyInput(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  State<Ks2ActLinesTable> createState() => _Ks2ActLinesTableState();
}

class _Ks2ActLinesTableState extends State<Ks2ActLinesTable> {
  static const double _wNo = 80;
  static const double _wUnit = 64;
  static const double _wQty = 96;
  static const double _wPrice = 104;
  static const double _wSum = 116;
  static const double _wDel = 36;
  static const double _rowHeight = 32;
  static const double _sectionHeaderHeight = 26;
  static const double _headerHeight = 30;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _qtyFocusNode = FocusNode();

  String? _editingQtyRowKey;

  /// Свернутые разделы (по умолчанию все свёрнуты).
  final Set<String> _collapsedSectionKeys = {};

  /// Ключи разделов, для которых уже задано начальное состояние свёрнутости.
  final Set<String> _initializedSectionKeys = {};

  bool get _hasDelete => widget.edit?.onDelete != null;

  String _sectionKeyForRow(Ks2ActLineRow row) {
    final t = row.sectionTitle.trim();
    return t.isEmpty ? '—' : t;
  }

  bool _isSectionExpanded(String sectionKey) =>
      !_collapsedSectionKeys.contains(sectionKey);

  void _toggleSection(String sectionKey) {
    final collapsing = _isSectionExpanded(sectionKey);
    String? editingToClose;
    if (collapsing) {
      final editingKey = _editingQtyRowKey;
      if (editingKey != null) {
        final editingRow =
            widget.rows.where((r) => r.rowKey == editingKey).firstOrNull;
        if (editingRow != null && _sectionKeyForRow(editingRow) == sectionKey) {
          editingToClose = editingKey;
        }
      }
    }

    setState(() {
      if (collapsing) {
        _collapsedSectionKeys.add(sectionKey);
      } else {
        _collapsedSectionKeys.remove(sectionKey);
      }
      if (editingToClose != null) {
        _qtyFocusNode.unfocus();
        final row =
            widget.rows.where((r) => r.rowKey == editingToClose).firstOrNull;
        if (row != null) {
          widget.edit?.onQtyBlur?.call(row);
        }
        if (_editingQtyRowKey == editingToClose) {
          _editingQtyRowKey = null;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _qtyFocusNode.addListener(_onQtyFocusChanged);
    for (final key in _headingSectionKeys()) {
      _initializedSectionKeys.add(key);
      _collapsedSectionKeys.add(key);
    }
  }

  @override
  void dispose() {
    _qtyFocusNode.removeListener(_onQtyFocusChanged);
    _scrollController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _onQtyFocusChanged() {
    if (_qtyFocusNode.hasFocus || _editingQtyRowKey == null || !mounted) {
      return;
    }
    _finishQtyEditForKey(_editingQtyRowKey!);
  }

  void _finishQtyEditForKey(String rowKey) {
    final edit = widget.edit;
    final row = widget.rows.where((r) => r.rowKey == rowKey).firstOrNull;
    if (row != null) {
      edit?.onQtyBlur?.call(row);
    }
    if (_editingQtyRowKey == rowKey) {
      setState(() => _editingQtyRowKey = null);
    }
  }

  void _dismissQtyEdit() {
    if (_editingQtyRowKey == null) return;
    _qtyFocusNode.unfocus();
    _finishQtyEditForKey(_editingQtyRowKey!);
  }

  Iterable<String> _headingSectionKeys() sync* {
    String? current;
    for (final row in widget.rows) {
      final key = _sectionKeyForRow(row);
      final showHeading = key != '—' || widget.rows.length > 1;
      if (showHeading && key != current) {
        current = key;
        yield key;
      }
    }
  }

  void _applyInitialSectionCollapse() {
    if (!mounted) return;
    final newKeys = <String>[];
    for (final key in _headingSectionKeys()) {
      if (_initializedSectionKeys.add(key)) {
        newKeys.add(key);
      }
    }
    if (newKeys.isEmpty) return;
    setState(() => _collapsedSectionKeys.addAll(newKeys));
  }

  List<_Ks2ListEntry> _buildEntries() {
    final entries = <_Ks2ListEntry>[];
    String? currentSection;
    final sectionRows = <Ks2ActLineRow>[];

    void emitSection(String sectionKey) {
      if (sectionRows.isEmpty) return;

      var total = 0.0;
      for (final r in sectionRows) {
        total += _amountForRow(r);
      }

      final showHeading = sectionKey != '—' || widget.rows.length > 1;
      if (showHeading) {
        entries.add(
          _Ks2ListEntry.sectionHeader(
            sectionKey,
            sectionKey == '—' ? 'Без названия раздела' : sectionKey,
            total,
          ),
        );
        if (_isSectionExpanded(sectionKey)) {
          for (final r in sectionRows) {
            entries.add(_Ks2ListEntry.dataRow(r, sectionKey));
          }
        }
      } else {
        for (final r in sectionRows) {
          entries.add(_Ks2ListEntry.dataRow(r, sectionKey));
        }
      }
      sectionRows.clear();
    }

    for (final row in widget.rows) {
      final key =
          row.sectionTitle.trim().isEmpty ? '—' : row.sectionTitle.trim();
      if (currentSection != key) {
        if (currentSection != null) {
          emitSection(currentSection);
        }
        currentSection = key;
      }
      sectionRows.add(row);
    }
    if (currentSection != null) {
      emitSection(currentSection);
    }

    return entries;
  }

  double _qtyForRow(Ks2ActLineRow row) {
    final edit = widget.edit;
    if (edit == null) return row.quantity;
    final c = edit.qtyControllers[row.rowKey];
    if (c == null) return row.quantity;
    return Ks2ActLinesTable.parseQty(c.text) ?? row.quantity;
  }

  double _amountForRow(Ks2ActLineRow row) => _qtyForRow(row) * row.price;

  @override
  void didUpdateWidget(covariant Ks2ActLinesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      if (_editingQtyRowKey != null &&
          !widget.rows.any((r) => r.rowKey == _editingQtyRowKey)) {
        _editingQtyRowKey = null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialSectionCollapse();
      });
    }
  }

  void _startQtyEdit(Ks2ActLineRow row) {
    if (widget.edit == null) return;
    final prevKey = _editingQtyRowKey;
    if (prevKey != null && prevKey != row.rowKey) {
      _finishQtyEditForKey(prevKey);
    }
    if (_editingQtyRowKey == row.rowKey) {
      return;
    }
    setState(() => _editingQtyRowKey = row.rowKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _qtyFocusNode.requestFocus();
    });
  }

  void _endQtyEdit(Ks2ActLineRow row) {
    if (widget.edit == null) return;
    _qtyFocusNode.unfocus();
    _finishQtyEditForKey(row.rowKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.rows.isEmpty) {
      return DecoratedBox(
        decoration: _outerDecoration(scheme),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            widget.emptyMessage ??
                'Нет строк для отображения в таблице работ.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }

    final entries = _buildEntries();
    final borderColor = scheme.outline.withValues(alpha: 0.15);
    final headerBg = scheme.surfaceContainerHighest.withValues(alpha: 0.4);

    final isQtyEditing = _editingQtyRowKey != null;

    return DecoratedBox(
      decoration: _outerDecoration(scheme),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: isQtyEditing ? _dismissQtyEdit : null,
              child: ColoredBox(
                color: headerBg,
                child: _HeaderRow(
                  hasDelete: _hasDelete,
                  borderColor: borderColor,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: isQtyEditing ? _dismissQtyEdit : null,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                  controller: _scrollController,
                  primary: false,
                  itemCount: entries.length,
                  itemExtentBuilder: (index, _) {
                    final e = entries[index];
                    return switch (e.kind) {
                      _Ks2ListEntryKind.sectionHeader => _sectionHeaderHeight,
                      _Ks2ListEntryKind.dataRow => _rowHeight,
                    };
                  },
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return switch (entry.kind) {
                      _Ks2ListEntryKind.sectionHeader => _SectionHeaderTile(
                        title: entry.sectionTitle!,
                        sectionTotal: entry.sectionTotal!,
                        isExpanded: _isSectionExpanded(entry.sectionKey!),
                        borderColor: borderColor,
                        hasDelete: _hasDelete,
                        onTap: () => _toggleSection(entry.sectionKey!),
                      ),
                      _Ks2ListEntryKind.dataRow => _DataRowTile(
                        row: entry.row!,
                        borderColor: borderColor,
                        hasDelete: _hasDelete,
                        qty: _qtyForRow(entry.row!),
                        amount: _amountForRow(entry.row!),
                        isModified: widget.edit?.modifiedRowKeys
                                .contains(entry.row!.rowKey) ??
                            false,
                        isInvalid: widget.edit?.invalidRowKeys
                                .contains(entry.row!.rowKey) ??
                            false,
                        isEditing: _editingQtyRowKey == entry.row!.rowKey,
                        edit: widget.edit,
                        qtyFocusNode: _qtyFocusNode,
                        onStartEdit: () => _startQtyEdit(entry.row!),
                        onEndEdit: () => _endQtyEdit(entry.row!),
                        onRowTap: isQtyEditing ? _dismissQtyEdit : null,
                      ),
                    };
                  },
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: isQtyEditing ? _dismissQtyEdit : null,
              child: _buildFooter(
                theme: theme,
                scheme: scheme,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _outerDecoration(ColorScheme scheme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      color: scheme.surfaceContainerLowest.withValues(alpha: 0.2),
    );
  }

  Widget _buildFooter({
    required ThemeData theme,
    required ColorScheme scheme,
    required Color borderColor,
  }) {
    final footer = widget.financialFooter;
    final valueStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface.withValues(alpha: 0.72),
    );

    Widget totalChip(String label, String value, {bool emphasize = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 6),
          Text(
            value,
            style: emphasize
                ? valueStyle?.copyWith(
                    fontSize: (valueStyle.fontSize ?? 14) + 1,
                  )
                : valueStyle,
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.1),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: footer != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  totalChip('Сумма:', formatCurrency(footer.amount)),
                  const SizedBox(width: 20),
                  if (footer.vatAmount > 0) ...[
                    totalChip('НДС:', formatCurrency(footer.vatAmount)),
                    const SizedBox(width: 20),
                  ],
                  totalChip(
                    'К оплате:',
                    formatCurrency(footer.totalToPay),
                    emphasize: true,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Итого:', style: valueStyle),
                  const SizedBox(width: 16),
                  Text(formatCurrency(widget.totalAmount), style: valueStyle),
                ],
              ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.hasDelete,
    required this.borderColor,
  });

  final bool hasDelete;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 11,
      height: 1.2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SizedBox(
        height: _Ks2ActLinesTableState._headerHeight,
        child: Row(
          children: [
            _HeadCell(width: _Ks2ActLinesTableState._wNo, child: Text('№', style: style)),
            Expanded(
              child: _HeadCell(
                child: Text('Наименование', style: style),
              ),
            ),
            _HeadCell(
              width: _Ks2ActLinesTableState._wUnit,
              child: Text('Ед.', style: style),
            ),
            _HeadCell(
              width: _Ks2ActLinesTableState._wQty,
              align: TextAlign.end,
              child: Text('Кол-во', style: style),
            ),
            _HeadCell(
              width: _Ks2ActLinesTableState._wPrice,
              align: TextAlign.end,
              child: Text('Цена', style: style),
            ),
            _HeadCell(
              width: _Ks2ActLinesTableState._wSum,
              align: TextAlign.end,
              child: Text('Сумма', style: style),
            ),
            if (hasDelete) const SizedBox(width: _Ks2ActLinesTableState._wDel),
          ],
        ),
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell({
    required this.child,
    this.width,
    this.align = TextAlign.center,
  });

  final Widget child;
  final double? width;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: align == TextAlign.end
          ? Alignment.centerRight
          : Alignment.center,
      child: child,
    );
    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return content;
  }
}

class _SectionHeaderTile extends StatelessWidget {
  const _SectionHeaderTile({
    required this.title,
    required this.sectionTotal,
    required this.isExpanded,
    required this.borderColor,
    required this.hasDelete,
    required this.onTap,
  });

  final String title;
  final double sectionTotal;
  final bool isExpanded;
  final Color borderColor;
  final bool hasDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final headerBg = scheme.primaryContainer.withValues(
      alpha: isDark ? 0.38 : 0.55,
    );
    final headerFg = scheme.onPrimaryContainer;
    final titleStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 11,
      color: headerFg,
      letterSpacing: 0.15,
    );
    final totalStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 11,
      color: headerFg,
    );

    return Semantics(
      button: true,
      expanded: isExpanded,
      label: '$title, итого ${formatAmount(sectionTotal)}',
      child: Material(
        color: headerBg,
        child: InkWell(
          onTap: onTap,
          splashColor: scheme.primary.withValues(alpha: 0.12),
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: scheme.primary.withValues(alpha: 0.22),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_right,
                    size: 13,
                    color: headerFg.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Итого:',
                    style: totalStyle?.copyWith(
                      color: headerFg.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: _Ks2ActLinesTableState._wSum,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatAmount(sectionTotal),
                        style: totalStyle,
                      ),
                    ),
                  ),
                  if (hasDelete)
                    const SizedBox(width: _Ks2ActLinesTableState._wDel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataRowTile extends StatelessWidget {
  const _DataRowTile({
    required this.row,
    required this.borderColor,
    required this.hasDelete,
    required this.qty,
    required this.amount,
    required this.isModified,
    required this.isInvalid,
    required this.isEditing,
    required this.edit,
    required this.qtyFocusNode,
    required this.onStartEdit,
    required this.onEndEdit,
    this.onRowTap,
  });

  final Ks2ActLineRow row;
  final Color borderColor;
  final bool hasDelete;
  final double qty;
  final double amount;
  final bool isModified;
  final bool isInvalid;
  final bool isEditing;
  final Ks2ActLinesTableEditConfig? edit;
  final FocusNode qtyFocusNode;
  final VoidCallback onStartEdit;
  final VoidCallback onEndEdit;
  final VoidCallback? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      height: 1.15,
    );

    Color? bg;
    if (isModified) {
      bg = scheme.tertiaryContainer.withValues(alpha: 0.3);
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onRowTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
        children: [
          SizedBox(
            width: _Ks2ActLinesTableState._wNo,
            child: Text(
              row.estimateNumber.isEmpty ? '—' : row.estimateNumber,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cellStyle,
              ),
            ),
          ),
          SizedBox(
            width: _Ks2ActLinesTableState._wUnit,
            child: Text(
              row.unit,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
          ),
          SizedBox(
            width: _Ks2ActLinesTableState._wQty,
            child: _QtyCell(
              row: row,
              qty: qty,
              isEditing: isEditing,
              isInvalid: isInvalid,
              edit: edit,
              focusNode: qtyFocusNode,
              onStartEdit: onStartEdit,
              onEndEdit: onEndEdit,
            ),
          ),
          SizedBox(
            width: _Ks2ActLinesTableState._wPrice,
            child: Text(
              formatAmount(row.price),
              textAlign: TextAlign.end,
              style: cellStyle,
            ),
          ),
          SizedBox(
            width: _Ks2ActLinesTableState._wSum,
            child: Text(
              formatAmount(amount),
              textAlign: TextAlign.end,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (hasDelete)
            SizedBox(
              width: _Ks2ActLinesTableState._wDel,
              child: PermissionGuard(
                module: 'contracts',
                permission: 'update',
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => edit?.onDelete?.call(row),
                  icon: Icon(
                    CupertinoIcons.trash,
                    size: 14,
                    color: scheme.error.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _QtyCell extends StatelessWidget {
  const _QtyCell({
    required this.row,
    required this.qty,
    required this.isEditing,
    required this.isInvalid,
    required this.edit,
    required this.focusNode,
    required this.onStartEdit,
    required this.onEndEdit,
  });

  final Ks2ActLineRow row;
  final double qty;
  final bool isEditing;
  final bool isInvalid;
  final Ks2ActLinesTableEditConfig? edit;
  final FocusNode focusNode;
  final VoidCallback onStartEdit;
  final VoidCallback onEndEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (edit != null && isEditing) {
      final controller = edit!.qtyControllers[row.rowKey]!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textAlign: TextAlign.end,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.\s]')),
          ],
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: isInvalid ? scheme.error : scheme.primary,
              ),
            ),
          ),
          onChanged: (_) => edit!.onQtyChanged(),
          onEditingComplete: onEndEdit,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
            onEndEdit();
          },
        ),
      );
    }

    final display = edit != null
        ? formatQuantity(qty)
        : formatQuantity(row.quantity);

    if (edit == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          display,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStartEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              display,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isInvalid
                    ? scheme.error
                    : scheme.primary.withValues(alpha: 0.9),
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Маппинг строки акта в [Ks2ActLineRow].
Ks2ActLineRow ks2ActLineRowFromContractActLine(ContractActLine line) {
  return Ks2ActLineRow(
    rowKey: line.id,
    sectionTitle: line.sectionTitle,
    estimateNumber: line.estimateNumber,
    name: ks2ActLineDisplayName(line.name),
    unit: line.unit,
    quantity: line.quantity,
    price: line.price,
    amount: line.amount,
    backlogQuantity: line.backlogQuantity,
  );
}
