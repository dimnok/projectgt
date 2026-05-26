import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_lines_editor_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_ks2_summary_scope.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_ks2_status_documents_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_retentions_fields.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_ks2_providers.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_excel_persist.dart';
import 'package:projectgt/features/ks2/presentation/services/ks2_form_header_export_service.dart';
import 'package:projectgt/presentation/widgets/custom_sliding_segmented_control.dart';

/// Шапка унифицированной формы № КС-2 (модуль «Договоры»).
///
/// Вверху — карточка контекста договора (объект, №, дата, сумма с НДС). Стороны в Excel
/// подставляются на сервере по [Contract], в форме не показываются.
/// **Доп. соглашения** — по кнопке: пары «номер — дата» (в пределах лимита выгрузки).
/// **Реквизиты акта** — номер (ввод), дата и период (календарь).
///
/// Ниже шапки можно передать [positionsSection] — например таблицу позиций по ВОР
/// из модуля «Договоры».
class ContractActKs2FormBody extends ConsumerStatefulWidget {
  /// Договор, в контексте которого открыт шаблон.
  final Contract contract;

  /// Блок под шапкой: таблица работ / позиции (опционально).
  final Widget? positionsSection;

  /// Возвращает id выбранной ВОР для выгрузки таблицы работ в Excel (`null` — только шапка).
  final String? Function()? getSelectedVorId;

  /// Сумма строк превью по выбранной ВОР (без НДС), если таблица загружена.
  final double? Function()? getPreviewLineTotal;

  /// Редактируемый акт (режим просмотра/правки существующей записи).
  final ContractAct? existingAct;

  /// Ключ секции строк акта (`contract_act_lines`).
  final GlobalKey<ContractActLinesEditorSectionState>? actLinesSectionKey;

  /// Ключ вкладки «Статус» (сохранение статусов с нижней кнопки).
  final GlobalKey<ContractActKs2StatusDocumentsSectionState>?
      statusDocumentsSectionKey;

  /// Создаёт виджет шаблона.
  const ContractActKs2FormBody({
    super.key,
    required this.contract,
    this.positionsSection,
    this.getSelectedVorId,
    this.getPreviewLineTotal,
    this.existingAct,
    this.actLinesSectionKey,
    this.statusDocumentsSectionKey,
  });

  @override
  ConsumerState<ContractActKs2FormBody> createState() =>
      ContractActKs2FormBodyState();
}

/// Состояние [ContractActKs2FormBody]; публично для экспорта через [GlobalKey].
class ContractActKs2FormBodyState extends ConsumerState<ContractActKs2FormBody>
    with SingleTickerProviderStateMixin {
  final List<_Ks2AddendumRowControllers> _addendumRows = [];
  late final TextEditingController _docNumberController;
  late final TextEditingController _actDocDateDisplay;
  late final TextEditingController _periodFromDisplay;
  late final TextEditingController _periodToDisplay;
  late final TextEditingController _advanceController;
  late final TextEditingController _warrantyController;
  late final TextEditingController _otherController;
  late final TextEditingController _totalDisplayController;

  late DateTime _actDocDate;
  late DateTime _periodFrom;
  late DateTime _periodTo;

  static const int _kMaxAddendumRows = 50;

  late final TabController _tabController;

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

  bool get _canEditHeader => widget.existingAct?.canEditFull ?? true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAct;
    final now = DateTime.now();
    if (existing != null) {
      _actDocDate = _dateOnly(existing.actDate);
      _periodFrom = _dateOnly(existing.periodFrom);
      _periodTo = _dateOnly(existing.periodTo);
    } else {
      _actDocDate = DateTime(now.year, now.month, now.day);
      _periodFrom = DateTime(now.year, now.month, 1);
      _periodTo = _actDocDate;
    }
    _docNumberController = TextEditingController(
      text: existing?.number ?? '',
    );
    _actDocDateDisplay = TextEditingController();
    _periodFromDisplay = TextEditingController();
    _periodToDisplay = TextEditingController();
    _advanceController = TextEditingController(
      text: existing != null
          ? existing.advanceRetention.toStringAsFixed(2)
          : '0',
    );
    _warrantyController = TextEditingController(
      text: existing != null
          ? existing.warrantyRetention.toStringAsFixed(2)
          : '0',
    );
    _otherController = TextEditingController(
      text: existing != null
          ? existing.otherRetentions.toStringAsFixed(2)
          : '0',
    );
    _totalDisplayController = TextEditingController();
    _syncActDateDisplays();
    _refreshTotalDisplay();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabIndexChanged);
  }

  void _onTabIndexChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChanged);
    _tabController.dispose();
    for (final row in _addendumRows) {
      row.dispose();
    }
    _addendumRows.clear();
    _docNumberController.dispose();
    _actDocDateDisplay.dispose();
    _periodFromDisplay.dispose();
    _periodToDisplay.dispose();
    _advanceController.dispose();
    _warrantyController.dispose();
    _otherController.dispose();
    _totalDisplayController.dispose();
    super.dispose();
  }

  double _readAmount(TextEditingController c) => parseAmount(c.text) ?? 0;

  /// База и НДС для расчёта «Итого к оплате» в шапке формы.
  ({double amount, double vatAmount}) _moneyPartsForTotal() {
    final existing = widget.existingAct;
    if (existing != null) {
      return (amount: existing.amount, vatAmount: existing.vatAmount);
    }
    final lineTotal = widget.getPreviewLineTotal?.call();
    if (lineTotal == null || lineTotal <= 0) {
      return (amount: 0, vatAmount: 0);
    }
    final split = splitActAmountForStorage(
      lineTotal: lineTotal,
      vatTerms: ContractVatTerms(
        vatRate: widget.contract.vatRate,
        isVatIncluded: widget.contract.isVatIncluded,
      ),
    );
    return (amount: split.amount, vatAmount: split.vatAmount);
  }

  /// Пересчитывает «Итого к оплате» после загрузки таблицы ВОР.
  void onPreviewLineTotalUpdated() {
    if (!mounted) return;
    setState(_refreshTotalDisplay);
  }

  void _refreshTotalDisplay() {
    final parts = _moneyPartsForTotal();
    ContractActRetentionsFields.refreshTotalDisplay(
      totalDisplayController: _totalDisplayController,
      advanceController: _advanceController,
      warrantyController: _warrantyController,
      otherController: _otherController,
      amount: parts.amount,
      vatAmount: parts.vatAmount,
    );
  }

  ContractActRetentionInput _collectRetentionInput() {
    return ContractActRetentionInput(
      advanceRetention: _readAmount(_advanceController),
      warrantyRetention: _readAmount(_warrantyController),
      otherRetentions: _readAmount(_otherController),
    );
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

  /// Сохраняет акт КС-2 в [contract_acts] по выбранной ВОР и полям формы.
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
        contractActsProvider(widget.contract.id).future,
      );
      if (acts.any((a) => a.isKs2 && a.vorId == vorId)) {
        if (!context.mounted) return false;
        AppSnackBar.show(
          context: context,
          message: 'По этой ВОР акт КС-2 уже сохранён',
          kind: AppSnackBarKind.warning,
        );
        return false;
      }

      final exportInput = _collectHeaderExportInput();
      final repository = ref.read(contractActRepositoryProvider);

      final retentions = _collectRetentionInput();
      final actId = await repository.createKs2Act(
        contractId: widget.contract.id,
        vorId: vorId,
        number: actNumber,
        actDate: _actDocDate,
        periodFrom: _periodFrom,
        periodTo: _periodTo,
        advanceRetention: retentions.advanceRetention,
        warrantyRetention: retentions.warrantyRetention,
        otherRetentions: retentions.otherRetentions,
      );

      await persistContractActExcelAfterCreate(
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

      ref.invalidate(contractActsProvider(widget.contract.id));
      ref.invalidate(contractActApprovedVorsProvider(widget.contract.id));

      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message: 'Акт КС-2 и файл Excel сохранены',
        kind: AppSnackBarKind.success,
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      final msg = e.toString();
      final actSavedButNoExcel = msg.contains('Акт сохранён');
      if (actSavedButNoExcel) {
        ref.invalidate(contractActsProvider(widget.contract.id));
        ref.invalidate(contractActApprovedVorsProvider(widget.contract.id));
        AppSnackBar.show(
          context: context,
          message:
              'Акт и строки в базе сохранены. Excel не сформирован — обновите Edge Function export-ks2-form-header на сервере.',
          kind: AppSnackBarKind.warning,
        );
        return true;
      }
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить акт: $e',
        kind: AppSnackBarKind.error,
      );
      return false;
    }
  }

  bool _validateActHeaderFields(BuildContext context) {
    if (_docNumberController.text.trim().isEmpty) {
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
    return true;
  }

  ({ContractActWorkflowStatus workflow, ContractActPaymentStatus payment})
      _resolveStatusesForSave(ContractAct act) {
    final pending =
        widget.statusDocumentsSectionKey?.currentState?.pendingStatuses;
    if (pending != null) {
      return (workflow: pending.workflow, payment: pending.payment);
    }
    return (workflow: act.workflowStatus, payment: act.paymentStatus);
  }

  /// Сохраняет удержания и реквизиты (без строк, Excel не сбрасывается).
  Future<bool> saveHeaderAndRetentions(BuildContext context, WidgetRef ref) async {
    final act = widget.existingAct;
    if (act == null) return false;
    if (!_validateActHeaderFields(context)) return false;

    try {
      final repository = ref.read(contractActRepositoryProvider);
      final retentions = _collectRetentionInput();
      final statuses = _resolveStatusesForSave(act);
      await repository.saveKs2HeaderAndRetentions(
        act: act,
        number: _docNumberController.text.trim(),
        actDate: _actDocDate,
        periodFrom: _periodFrom,
        periodTo: _periodTo,
        advanceRetention: retentions.advanceRetention,
        warrantyRetention: retentions.warrantyRetention,
        otherRetentions: retentions.otherRetentions,
        workflowStatus: statuses.workflow,
        paymentStatus: statuses.payment,
      );

      ref.invalidate(contractActsProvider(widget.contract.id));

      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message: 'Удержания и реквизиты сохранены',
        kind: AppSnackBarKind.success,
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить: $e',
        kind: AppSnackBarKind.error,
      );
      return false;
    }
  }

  /// Сохраняет реквизиты и объёмы строк существующего акта КС-2.
  Future<bool> saveExistingAct(BuildContext context, WidgetRef ref) async {
    final act = widget.existingAct;
    if (act == null) return false;
    if (!_validateActHeaderFields(context)) return false;

    final tabIndex = _tabController.index;
    final retentions = _collectRetentionInput();

    if (tabIndex == 2) {
      final statusSaved =
          await widget.statusDocumentsSectionKey?.currentState
              ?.saveStatusesIfDirty() ??
          false;
      if (!context.mounted) return statusSaved;
      if (statusSaved) return true;
      if (!statusSaved) {
        AppSnackBar.show(
          context: context,
          message: 'Измените статус или нажмите «Сохранить статусы»',
          kind: AppSnackBarKind.warning,
        );
      }
      return false;
    }

    if (!act.canEditFull || tabIndex == 1) {
      return saveHeaderAndRetentions(context, ref);
    }

    try {
      final repository = ref.read(contractActRepositoryProvider);
      final linesState = widget.actLinesSectionKey?.currentState;

      late final Map<String, double> quantities;
      late final Set<String> deletedLineIds;

      if (linesState != null) {
        quantities = linesState.buildQuantitiesByLineId();
        deletedLineIds = linesState.buildDeletedLineIds();
      } else {
        final lines = await repository.listActLines(act.id);
        quantities = {for (final l in lines) l.id: l.quantity};
        deletedLineIds = {};
      }

      if (!context.mounted) return false;

      if (quantities.isEmpty && deletedLineIds.isNotEmpty) {
        AppSnackBar.show(
          context: context,
          message: 'Нельзя удалить все строки акта',
          kind: AppSnackBarKind.warning,
        );
        return false;
      }

      await repository.saveKs2ActEdits(
        act: act,
        number: _docNumberController.text.trim(),
        actDate: _actDocDate,
        periodFrom: _periodFrom,
        periodTo: _periodTo,
        quantitiesByLineId: quantities,
        deletedLineIds: deletedLineIds,
        advanceRetention: retentions.advanceRetention,
        warrantyRetention: retentions.warrantyRetention,
        otherRetentions: retentions.otherRetentions,
      );

      ref.invalidate(contractActsProvider(widget.contract.id));
      ref.invalidate(contractActLinesProvider(act.id));
      ref.invalidate(contractActApprovedVorsProvider(widget.contract.id));

      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message:
            'Акт сохранён. Сформируйте Excel заново — старый файл сброшен.',
        kind: AppSnackBarKind.success,
      );
      return true;
    } on FormatException catch (e) {
      if (!context.mounted) return false;
      AppSnackBar.show(
        context: context,
        message: e.message,
        kind: AppSnackBarKind.warning,
      );
      return false;
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
  /// Поля шапки для Excel (вкладка «Статус»).
  ContractActKs2HeaderExportInput collectHeaderExportInput() {
    final i = _collectHeaderExportInput();
    return ContractActKs2HeaderExportInput(
      actNumber: i.actNumber,
      actDocDate: i.actDocDate,
      reportingPeriodFrom: i.reportingPeriodFrom,
      reportingPeriodTo: i.reportingPeriodTo,
      addenda: i.addenda,
      vorId: i.vorId,
    );
  }

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

  /// Выгружает КС-2 на устройство (черновик или сохранённый акт по [existingAct]).
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
        vorId: input.vorId ?? widget.existingAct?.vorId,
        actId: widget.existingAct?.id,
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

  /// Всегда видимая строка: №, даты, период.
  Widget _buildStickyActHeaderRow({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 22,
          child: _actCompactField(
            theme: theme,
            scheme: scheme,
            controller: _docNumberController,
            labelText: '№ акта',
            prefixIcon: CupertinoIcons.number,
            required: true,
            readOnly: !_canEditHeader,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 20,
          child: _actCompactField(
            theme: theme,
            scheme: scheme,
            controller: _actDocDateDisplay,
            labelText: 'Дата',
            prefixIcon: CupertinoIcons.calendar,
            required: true,
            readOnly: true,
            onTap: _canEditHeader
                ? () => _pickActDate(
                      context: context,
                      title: 'Дата составления акта',
                      initial: _actDocDate,
                      onPick: (d) => _actDocDate = d,
                    )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 20,
          child: _actCompactField(
            theme: theme,
            scheme: scheme,
            controller: _periodFromDisplay,
            labelText: 'Период с',
            prefixIcon: CupertinoIcons.calendar_badge_plus,
            readOnly: true,
            onTap: _canEditHeader
                ? () => _pickActDate(
                      context: context,
                      title: 'Начало отчётного периода',
                      initial: _periodFrom,
                      onPick: (d) => _periodFrom = d,
                    )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 20,
          child: _actCompactField(
            theme: theme,
            scheme: scheme,
            controller: _periodToDisplay,
            labelText: 'Период по',
            prefixIcon: CupertinoIcons.calendar_today,
            readOnly: true,
            onTap: _canEditHeader
                ? () => _pickActDate(
                      context: context,
                      title: 'Окончание отчётного периода',
                      initial: _periodTo,
                      onPick: (d) => _periodTo = d,
                    )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRetentionsPanel(ThemeData theme) {
    final parts = _moneyPartsForTotal();
    ContractActRetentionsFields.refreshTotalDisplay(
      totalDisplayController: _totalDisplayController,
      advanceController: _advanceController,
      warrantyController: _warrantyController,
      otherController: _otherController,
      amount: parts.amount,
      vatAmount: parts.vatAmount,
    );
    return ContractActRetentionsFields(
      advanceController: _advanceController,
      warrantyController: _warrantyController,
      otherController: _otherController,
      totalDisplayController: _totalDisplayController,
      amount: parts.amount,
      vatAmount: parts.vatAmount,
      enabled: _canEditHeader,
      compact: true,
      onChanged: () => setState(_refreshTotalDisplay),
    );
  }

  Widget _buildAddendaExpansion(ThemeData theme, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.45 : 0.65,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: Icon(
            CupertinoIcons.doc_on_doc,
            size: 18,
            color: scheme.primary.withValues(alpha: 0.85),
          ),
          title: Text(
            'Доп. соглашения',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            _addendumRows.isEmpty
                ? 'Не указаны — нажмите, чтобы добавить'
                : 'Записей: ${_addendumRows.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GTTextButton(
                text: 'Добавить',
                icon: CupertinoIcons.add,
                color: scheme.primary,
                fontSize: 13,
                dense: true,
                onPressed: _addendumRows.length >= _kMaxAddendumRows
                    ? null
                    : _addAddendumRow,
              ),
            ),
            if (_addendumRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._addendumRows.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;
                return Padding(
                  padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GTTextField(
                          controller: row.number,
                          labelText: 'Номер ${i + 1}',
                          prefixIcon: CupertinoIcons.doc_append,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GTTextField(
                          controller: row.date,
                          labelText: 'Дата',
                          hintText: 'дд.мм.гггг',
                          prefixIcon: CupertinoIcons.calendar,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Удалить',
                        icon: Icon(CupertinoIcons.trash, color: scheme.error),
                        onPressed: () => _removeAddendumAt(i),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ks2TabSegment({
    required ThemeData theme,
    required ColorScheme scheme,
    required String label,
    required IconData icon,
    required bool selected,
  }) {
    final color = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.52);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Переключатель вкладок «Позиции» / «Удержания» (сегментный контрол).
  Widget _buildKs2TabSwitcher(ThemeData theme, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final selected = _tabController.index;

    return CustomSlidingSegmentedControl<int>(
      groupValue: selected,
      onValueChanged: _tabController.animateTo,
      backgroundColor: scheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.48 : 0.72,
      ),
      thumbColor: scheme.surface,
      borderRadius: 10,
      padding: const EdgeInsets.all(3),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      children: {
        0: _ks2TabSegment(
          theme: theme,
          scheme: scheme,
          label: 'Позиции',
          icon: CupertinoIcons.list_bullet,
          selected: selected == 0,
        ),
        1: _ks2TabSegment(
          theme: theme,
          scheme: scheme,
          label: 'Удержания',
          icon: CupertinoIcons.minus_rectangle,
          selected: selected == 1,
        ),
        2: _ks2TabSegment(
          theme: theme,
          scheme: scheme,
          label: 'Статус',
          icon: CupertinoIcons.flag_fill,
          selected: selected == 2,
        ),
      },
    );
  }

  String _contractOneLine(Contract contract) {
    final object = contract.objectName?.trim();
    final parts = <String>[
      'Договор № ${contract.number.trim()}',
      if (object != null && object.isNotEmpty) object,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCreate = widget.existingAct == null;

    final positionsChild = widget.positionsSection != null
        ? RepaintBoundary(child: widget.positionsSection!)
        : Center(
            child: Text(
              'Таблица позиций не подключена.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          );

    return ContractActKs2SummaryScope(
      vatTerms: ContractVatTerms(
        vatRate: widget.contract.vatRate,
        isVatIncluded: widget.contract.isVatIncluded,
      ),
      advanceRetention: _readAmount(_advanceController),
      warrantyRetention: _readAmount(_warrantyController),
      otherRetentions: _readAmount(_otherController),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCreate) ...[
            Text(
              _contractOneLine(widget.contract),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _buildStickyActHeaderRow(
            context: context,
            theme: theme,
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _buildKs2TabSwitcher(theme, scheme),
          const SizedBox(height: 10),
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              sizing: StackFit.expand,
              children: [
                positionsChild,
                SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRetentionsPanel(theme),
                      const SizedBox(height: 8),
                      _buildAddendaExpansion(theme, scheme),
                    ],
                  ),
                ),
                ContractActKs2StatusDocumentsSection(
                  key: widget.statusDocumentsSectionKey,
                  contract: widget.contract,
                  act: widget.existingAct,
                  collectHeaderExportInput: collectHeaderExportInput,
                ),
              ],
            ),
          ),
        ],
      ),
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
