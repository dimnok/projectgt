import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_ks2_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_ks2_act_excel_persist.dart';
import 'package:projectgt/features/ks2/presentation/services/ks2_form_header_export_service.dart';

/// Шаблон шапки унифицированной формы № КС-2 в модуле «Договоры».
///
/// Вверху — карточка контекста договора (объект, №, дата, сумма с НДС). Стороны в Excel
/// подставляются на сервере по [Contract], в форме не показываются.
/// **Доп. соглашения** — по кнопке: пары «номер — дата» (в пределах лимита выгрузки).
/// **Реквизиты акта** — номер (ввод), дата и период (календарь).
///
/// Ниже шапки можно передать [positionsSection] — например таблицу позиций по ВОР
/// из модуля «Договоры».
class Ks2ActFormTemplate extends ConsumerStatefulWidget {
  /// Договор, в контексте которого открыт шаблон.
  final Contract contract;

  /// Блок под шапкой: таблица работ / позиции (опционально).
  final Widget? positionsSection;

  /// Возвращает id выбранной ВОР для выгрузки таблицы работ в Excel (`null` — только шапка).
  final String? Function()? getSelectedVorId;

  /// Создаёт виджет шаблона.
  const Ks2ActFormTemplate({
    super.key,
    required this.contract,
    this.positionsSection,
    this.getSelectedVorId,
  });

  @override
  ConsumerState<Ks2ActFormTemplate> createState() => Ks2ActFormTemplateState();
}

/// Состояние [Ks2ActFormTemplate]; публично для вызова экспорта через [GlobalKey].
class Ks2ActFormTemplateState extends ConsumerState<Ks2ActFormTemplate> {
  final List<_Ks2AddendumRowControllers> _addendumRows = [];
  late final TextEditingController _docNumberController;
  late final TextEditingController _actDocDateDisplay;
  late final TextEditingController _periodFromDisplay;
  late final TextEditingController _periodToDisplay;

  late DateTime _actDocDate;
  late DateTime _periodFrom;
  late DateTime _periodTo;

  static const int _kMaxAddendumRows = 50;

  void _addAddendumRow() {
    if (_addendumRows.length >= _kMaxAddendumRows) return;
    setState(() {
      _addendumRows.add(_Ks2AddendumRowControllers());
    });
  }

  void _removeAddendumAt(int index) {
    if (index < 0 || index >= _addendumRows.length) return;
    setState(() {
      _addendumRows.removeAt(index).dispose();
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _actDocDate = DateTime(now.year, now.month, now.day);
    _periodFrom = DateTime(now.year, now.month, 1);
    _periodTo = _actDocDate;
    _docNumberController = TextEditingController();
    _actDocDateDisplay = TextEditingController();
    _periodFromDisplay = TextEditingController();
    _periodToDisplay = TextEditingController();
    _syncActDateDisplays();
  }

  @override
  void dispose() {
    for (final row in _addendumRows) {
      row.dispose();
    }
    _addendumRows.clear();
    _docNumberController.dispose();
    _actDocDateDisplay.dispose();
    _periodFromDisplay.dispose();
    _periodToDisplay.dispose();
    super.dispose();
  }

  static const String _ruDatePattern = 'dd.MM.yyyy';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _syncActDateDisplays() {
    _actDocDateDisplay.text = formatRuDate(_actDocDate);
    _periodFromDisplay.text = formatRuDate(_periodFrom);
    _periodToDisplay.text = formatRuDate(_periodTo);
  }

  Future<void> _pickActDate({
    required BuildContext context,
    required String title,
    required DateTime initial,
    required ValueChanged<DateTime> onPick,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: title,
    );
    if (picked == null || !mounted) return;
    setState(() {
      onPick(_dateOnly(picked));
      _syncActDateDisplays();
    });
  }

  /// Сохраняет акт КС-2 в [ks2_acts] по выбранной ВОР и полям формы.
  ///
  /// Возвращает `true`, если запись создана. После `await` проверяет [BuildContext.mounted].
  Future<bool> saveAct(BuildContext context, WidgetRef ref) async {
    final vorId = widget.getSelectedVorId?.call();
    if (vorId == null || vorId.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Выберите утверждённую ВОР для таблицы позиций',
        kind: AppSnackBarKind.warning,
      );
      return false;
    }

    final actNumber = _docNumberController.text.trim();
    if (actNumber.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Введите номер акта',
        kind: AppSnackBarKind.warning,
      );
      return false;
    }

    if (_periodTo.isBefore(_periodFrom)) {
      AppSnackBar.show(
        context: context,
        message: 'Дата окончания периода не может быть раньше даты начала',
        kind: AppSnackBarKind.warning,
      );
      return false;
    }

    try {
      final acts = await ref.read(
        contractKs2ActsProvider(widget.contract.id).future,
      );
      if (acts.any((a) => a.vorId == vorId)) {
        if (!context.mounted) return false;
        AppSnackBar.show(
          context: context,
          message: 'По этой ВОР акт КС-2 уже сохранён',
          kind: AppSnackBarKind.warning,
        );
        return false;
      }

      final exportInput = _collectHeaderExportInput();

      final actId = await ref
          .read(contractKs2CreationProvider.notifier)
          .createAct(
            contractId: widget.contract.id,
            vorId: vorId,
            number: actNumber,
            date: _actDocDate,
          );

      await persistKs2ActExcelAfterCreate(
        ref: ref,
        companyId: widget.contract.companyId,
        contractId: widget.contract.id,
        actId: actId,
        vorId: vorId,
        actNumber: exportInput.actNumber,
        actDocDate: exportInput.actDocDate,
        reportingPeriodFrom: exportInput.reportingPeriodFrom,
        reportingPeriodTo: exportInput.reportingPeriodTo,
        addenda: exportInput.addenda,
      );

      ref.invalidate(contractKs2ActsProvider(widget.contract.id));
      ref.invalidate(contractKs2ApprovedVorsProvider(widget.contract.id));

      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message: 'Акт КС-2 и файл Excel сохранены',
        kind: AppSnackBarKind.success,
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить акт: $e',
        kind: AppSnackBarKind.error,
      );
      return false;
    }
  }

  /// Выгружает шапку КС-2 в Excel с полями из текущей формы (номер акта, даты, отчётный период, доп. соглашения).
  ///
  /// Показывает [AppSnackBar] об успехе или ошибке; после `await` использует [BuildContext.mounted].
  _Ks2HeaderExportInput _collectHeaderExportInput() {
    final actNumber = _docNumberController.text.trim();
    final actDocDate = _actDocDate;
    final periodFrom = _periodFrom;
    final periodTo = _periodTo;
    final addenda = <Ks2HeaderAddendumInput>[];
    for (final row in _addendumRows) {
      final n = row.number.text.trim();
      final d = parseDate(row.date.text.trim(), _ruDatePattern);
      if (n.isNotEmpty || d != null) {
        addenda.add(
          Ks2HeaderAddendumInput(number: n.isEmpty ? null : n, date: d),
        );
      }
    }
    final vorId = widget.getSelectedVorId?.call();
    return _Ks2HeaderExportInput(
      actNumber: actNumber.isEmpty ? null : actNumber,
      actDocDate: actDocDate,
      reportingPeriodFrom: periodFrom,
      reportingPeriodTo: periodTo,
      addenda: addenda,
      vorId: vorId,
    );
  }

  Future<void> exportHeaderDraftToDevice(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final input = _collectHeaderExportInput();

      await Ks2FormHeaderExportService.exportDraftHeaderToDevice(
        client: client,
        companyId: widget.contract.companyId,
        contractId: widget.contract.id,
        actNumber: input.actNumber,
        actDocDate: input.actDocDate,
        reportingPeriodFrom: input.reportingPeriodFrom,
        reportingPeriodTo: input.reportingPeriodTo,
        addenda: input.addenda,
        vorId: input.vorId,
      );
      if (!context.mounted) return;
      final withPositions = input.vorId != null && input.vorId!.isNotEmpty;
      AppSnackBar.show(
        context: context,
        message: withPositions
            ? 'КС-2 с таблицей работ сформирован. Если открылся диалог — выберите место сохранения.'
            : 'Черновик КС-2 (только шапка) сформирован. Для таблицы работ выберите ВОР в форме. '
                  'Если открылся диалог — выберите место сохранения.',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сформировать КС-2: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Компактное поле реквизитов акта ([readOnly] — выбор даты из календаря).
  Widget _actCompactField({
    required ThemeData theme,
    required ColorScheme scheme,
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final fill = scheme.surface.withValues(alpha: isDark ? 0.5 : 0.92);
    final borderColor = scheme.outline.withValues(alpha: 0.14);

    return GTTextField(
      controller: controller,
      labelText: required ? '$labelText *' : labelText,
      prefixIcon: prefixIcon,
      readOnly: readOnly,
      onTap: onTap,
      fillColor: fill,
      borderSide: BorderSide(color: borderColor),
      focusedBorderSide: BorderSide(color: scheme.primary, width: 1.25),
      prefixIconColor: scheme.primary.withValues(alpha: 0.85),
      prefixIconSize: 16,
      borderRadius: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  /// Компактная строка: номер, дата и период акта (даты — через календарь).
  Widget _buildActDetailsInputSection({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(theme, 'Реквизиты акта'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 28,
              child: _actCompactField(
                theme: theme,
                scheme: scheme,
                controller: _docNumberController,
                labelText: '№ акта',
                prefixIcon: CupertinoIcons.number,
                required: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 24,
              child: _actCompactField(
                theme: theme,
                scheme: scheme,
                controller: _actDocDateDisplay,
                labelText: 'Дата',
                prefixIcon: CupertinoIcons.calendar,
                required: true,
                readOnly: true,
                onTap: () => _pickActDate(
                  context: context,
                  title: 'Дата составления акта',
                  initial: _actDocDate,
                  onPick: (d) => _actDocDate = d,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 24,
              child: _actCompactField(
                theme: theme,
                scheme: scheme,
                controller: _periodFromDisplay,
                labelText: 'Период с',
                prefixIcon: CupertinoIcons.calendar_badge_plus,
                readOnly: true,
                onTap: () => _pickActDate(
                  context: context,
                  title: 'Начало отчётного периода',
                  initial: _periodFrom,
                  onPick: (d) => _periodFrom = d,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 24,
              child: _actCompactField(
                theme: theme,
                scheme: scheme,
                controller: _periodToDisplay,
                labelText: 'Период по',
                prefixIcon: CupertinoIcons.calendar_today,
                readOnly: true,
                onTap: () => _pickActDate(
                  context: context,
                  title: 'Окончание отчётного периода',
                  initial: _periodTo,
                  onPick: (d) => _periodTo = d,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Фрагменты контекста договора для шапки формы КС-2.
  static ({
    String objectName,
    String contractNumber,
    String contractDate,
    String amountTotal,
    String? amountVatDetail,
  })
  _contractContextParts(Contract contract) {
    final objectName = contract.objectName?.trim() ?? '';
    final contractNumber = contract.number.trim();
    final contractDate = formatRuDate(contract.date);

    if (contract.amount <= 0) {
      return (
        objectName: objectName,
        contractNumber: contractNumber,
        contractDate: contractDate,
        amountTotal: '',
        amountVatDetail: null,
      );
    }

    final amountTotal = formatCurrency(contract.amount);
    final hasVat = contract.vatAmount > 0 || contract.vatRate > 0;
    if (!hasVat) {
      return (
        objectName: objectName,
        contractNumber: contractNumber,
        contractDate: contractDate,
        amountTotal: amountTotal,
        amountVatDetail: null,
      );
    }

    final vatSum = contract.vatAmount > 0
        ? formatCurrency(contract.vatAmount)
        : '';
    final ratePart = contract.vatRate > 0
        ? ' (${contract.vatRate.toStringAsFixed(0)}%)'
        : '';

    String? amountVatDetail;
    if (contract.isVatIncluded) {
      if (vatSum.isNotEmpty) {
        amountVatDetail = 'в том числе НДС $vatSum$ratePart';
      }
    } else if (vatSum.isNotEmpty) {
      amountVatDetail = 'НДС сверху $vatSum$ratePart';
    } else if (ratePart.isNotEmpty) {
      amountVatDetail = 'НДС сверху$ratePart';
    }

    return (
      objectName: objectName,
      contractNumber: contractNumber,
      contractDate: contractDate,
      amountTotal: amountTotal,
      amountVatDetail: amountVatDetail,
    );
  }

  /// Карточка контекста договора: объект слева, сумма справа (KPI-блок).
  Widget _buildContractContextBanner({
    required ThemeData theme,
    required ColorScheme scheme,
    required Contract contract,
  }) {
    final parts = _contractContextParts(contract);
    final isDark = scheme.brightness == Brightness.dark;
    final cardFill = scheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.38 : 0.72,
    );
    final amountFill = scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08);
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    Widget metaLine(IconData icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      );
    }

    final metaRows = <Widget>[];
    if (parts.contractNumber.isNotEmpty) {
      metaRows.add(
        metaLine(CupertinoIcons.doc_text, '№ ${parts.contractNumber}'),
      );
    }
    metaRows.add(metaLine(CupertinoIcons.calendar, parts.contractDate));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cardFill,
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 20,
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.35),
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 58,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.building_2_fill,
                          size: 22,
                          color: scheme.primary.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ДОГОВОР',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.05,
                                fontSize: 9.5,
                                color: scheme.primary.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parts.objectName.isNotEmpty
                                  ? parts.objectName
                                  : 'Объект не указан',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: metaRows,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: scheme.outline.withValues(alpha: 0.12),
              ),
              Expanded(
                flex: 42,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: amountFill),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'СУММА ДОГОВОРА',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.85,
                            fontSize: 9,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          parts.amountTotal.isNotEmpty
                              ? parts.amountTotal
                              : '—',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (parts.amountVatDetail != null &&
                            parts.amountVatDetail!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(
                                alpha: isDark ? 0.35 : 0.65,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                parts.amountVatDetail!,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildContractContextBanner(
                  theme: theme,
                  scheme: scheme,
                  contract: widget.contract,
                ),
                const SizedBox(height: 20),
                _sectionTitle(theme, 'Доп. соглашения'),
                Semantics(
                  button: true,
                  label: 'Добавить дополнительное соглашение к договору',
                  hint: _addendumRows.length >= _kMaxAddendumRows
                      ? 'Достигнуто максимальное число записей'
                      : null,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GTTextButton(
                      text: 'Доп. соглашение',
                      icon: CupertinoIcons.add,
                      color: scheme.primary,
                      fontSize: 13,
                      dense: true,
                      onPressed: _addendumRows.length >= _kMaxAddendumRows
                          ? null
                          : _addAddendumRow,
                    ),
                  ),
                ),
                if (_addendumRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._addendumRows.asMap().entries.expand((e) {
                    final i = e.key;
                    final row = e.value;
                    return [
                      if (i > 0) const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GTTextField(
                              controller: row.number,
                              labelText: 'Доп. соглашение ${i + 1} — номер',
                              prefixIcon: CupertinoIcons.doc_append,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GTTextField(
                              controller: row.date,
                              labelText: 'Дата',
                              hintText: 'дд.мм.гггг',
                              prefixIcon: CupertinoIcons.calendar,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: GTTextButton(
                              text: 'Удалить',
                              icon: CupertinoIcons.trash,
                              color: scheme.error,
                              fontSize: 13,
                              onPressed: () => _removeAddendumAt(i),
                            ),
                          ),
                        ],
                      ),
                    ];
                  }),
                ],
                const SizedBox(height: 20),
                _buildActDetailsInputSection(
                  context: context,
                  theme: theme,
                  scheme: scheme,
                ),
                const SizedBox(height: 20),
                _sectionTitle(theme, 'Таблица работ (позиции)'),
              ],
            ),
          ),
        ),
        if (widget.positionsSection != null)
          Expanded(child: widget.positionsSection!)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
              color: scheme.surfaceContainerLow.withValues(alpha: 0.35),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Text(
                'Таблицу позиций можно подключить снаружи через параметр '
                '[Ks2ActFormTemplate.positionsSection] (см. модуль «Договоры»).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Поля шапки КС-2 для выгрузки Excel (форма и сохранение акта).
class _Ks2HeaderExportInput {
  const _Ks2HeaderExportInput({
    this.actNumber,
    this.actDocDate,
    this.reportingPeriodFrom,
    this.reportingPeriodTo,
    this.addenda = const [],
    this.vorId,
  });

  final String? actNumber;
  final DateTime? actDocDate;
  final DateTime? reportingPeriodFrom;
  final DateTime? reportingPeriodTo;
  final List<Ks2HeaderAddendumInput> addenda;
  final String? vorId;
}

/// Контроллеры одной строки «номер / дата» доп. соглашения в форме шапки КС-2.
class _Ks2AddendumRowControllers {
  /// Создаёт пару полей ввода.
  _Ks2AddendumRowControllers()
    : number = TextEditingController(),
      date = TextEditingController();

  /// Номер доп. соглашения.
  final TextEditingController number;

  /// Дата доп. соглашения (текст `дд.мм.гггг`).
  final TextEditingController date;

  /// Освобождает контроллеры.
  void dispose() {
    number.dispose();
    date.dispose();
  }
}
