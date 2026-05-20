import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/ks2/presentation/providers/ks2_counterparty_providers.dart';
import 'package:projectgt/features/ks2/presentation/services/ks2_form_header_export_service.dart';
import 'package:projectgt/features/ks2/presentation/utils/ks2_act_party_requisites.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';

/// Шаблон шапки унифицированной формы № КС-2.
///
/// Заказчик и подрядчик **подставляются из договора** (тип договора, контрагент по договору,
/// реквизиты компании из справочника) вместе с **ОКПО** — только просмотр, без редактирования.
/// **Стройка (адрес)** — только просмотр, из карточки объекта по [Contract.objectId] после загрузки списка объектов.
/// **Объект (наименование)** — только просмотр, из [Contract.objectName].
/// **Номер и дата договора** — только просмотр, из [Contract].
/// **Доп. соглашения** — по кнопке: сколько угодно пар «номер — дата» (в пределах лимита выгрузки), изначально блок пустой.
/// Остальные поля шапки по-прежнему можно менять. Сумма договора и НДС — из [Contract].
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
  String _customerRequisites = '';
  String _customerOkpo = '';
  String _contractorRequisites = '';
  String _contractorOkpo = '';
  String _constructionSiteDisplay = '';

  late final TextEditingController _okdpController;
  final List<_Ks2AddendumRowControllers> _addendumRows = [];
  late final TextEditingController _docNumberController;
  late final TextEditingController _docDateController;
  late final TextEditingController _periodFromController;
  late final TextEditingController _periodToController;
  late final TextEditingController _estimateCostController;
  late final TextEditingController _vatRateController;
  late final TextEditingController _vatAmountController;

  bool _partyAutoFilled = false;
  bool _partyAutoFillScheduled = false;
  bool _constructionAddressApplied = false;

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
    final c = widget.contract;
    _okdpController = TextEditingController();
    _docNumberController = TextEditingController();
    _docDateController = TextEditingController();
    _periodFromController = TextEditingController();
    _periodToController = TextEditingController();
    _estimateCostController = TextEditingController(
      text: c.amount > 0 ? formatAmount(c.amount) : '',
    );
    _vatRateController = TextEditingController(
      text: c.vatRate > 0 ? c.vatRate.toStringAsFixed(0) : '',
    );
    _vatAmountController = TextEditingController(
      text: c.vatAmount > 0 ? formatAmount(c.vatAmount) : '',
    );
  }

  @override
  void dispose() {
    _okdpController.dispose();
    for (final row in _addendumRows) {
      row.dispose();
    }
    _addendumRows.clear();
    _docNumberController.dispose();
    _docDateController.dispose();
    _periodFromController.dispose();
    _periodToController.dispose();
    _estimateCostController.dispose();
    _vatRateController.dispose();
    _vatAmountController.dispose();
    super.dispose();
  }

  static const String _ruDatePattern = 'dd.MM.yyyy';

  /// Выгружает шапку КС-2 в Excel с полями из текущей формы (номер акта, даты, отчётный период, доп. соглашения).
  ///
  /// Показывает [AppSnackBar] об успехе или ошибке; после `await` использует [BuildContext.mounted].
  Future<void> exportHeaderDraftToDevice(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final actNumber = _docNumberController.text.trim();
      final actDocDate =
          parseDate(_docDateController.text.trim(), _ruDatePattern);
      final periodFrom =
          parseDate(_periodFromController.text.trim(), _ruDatePattern);
      final periodTo =
          parseDate(_periodToController.text.trim(), _ruDatePattern);
      final addenda = <Ks2HeaderAddendumInput>[];
      for (final row in _addendumRows) {
        final n = row.number.text.trim();
        final d = parseDate(row.date.text.trim(), _ruDatePattern);
        if (n.isNotEmpty || d != null) {
          addenda.add(
            Ks2HeaderAddendumInput(
              number: n.isEmpty ? null : n,
              date: d,
            ),
          );
        }
      }
      final vorId = widget.getSelectedVorId?.call();

      await Ks2FormHeaderExportService.exportDraftHeaderToDevice(
        client: client,
        companyId: widget.contract.companyId,
        contractId: widget.contract.id,
        actNumber: actNumber.isEmpty ? null : actNumber,
        actDocDate: actDocDate,
        reportingPeriodFrom: periodFrom,
        reportingPeriodTo: periodTo,
        addenda: addenda,
        vorId: vorId,
      );
      if (!context.mounted) return;
      final withPositions = vorId != null && vorId.isNotEmpty;
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

  void _fillPartyFieldsFromContract({
    required CompanyProfile? profile,
    required List<Contractor> contractors,
  }) {
    if (!mounted) return;
    final defaults = ks2DefaultPartyPickIds(
      contract: widget.contract,
      contractors: contractors,
      hasCompanyProfile: profile != null,
    );

    String requisites(String? pickId) {
      if (pickId == null ||
          !ks2IsValidPartyPickId(pickId, profile: profile, contractors: contractors)) {
        return '';
      }
      return ks2PartyRequisitesMultiline(
        pickId: pickId,
        profile: profile,
        contractors: contractors,
      );
    }

    String okpo(String? pickId) {
      if (pickId == null ||
          !ks2IsValidPartyPickId(pickId, profile: profile, contractors: contractors)) {
        return '';
      }
      return ks2PartyOkpoText(
        pickId: pickId,
        profile: profile,
        contractors: contractors,
      );
    }

    setState(() {
      _customerRequisites = requisites(defaults.customerPickId);
      _customerOkpo = okpo(defaults.customerPickId);
      _contractorRequisites = requisites(defaults.contractorPickId);
      _contractorOkpo = okpo(defaults.contractorPickId);
    });
  }

  void _schedulePartyAutoFillIfNeeded({
    required CompanyProfile? profile,
    required List<Contractor> contractors,
  }) {
    if (_partyAutoFilled || _partyAutoFillScheduled) return;
    _partyAutoFillScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _partyAutoFilled) return;
      _partyAutoFilled = true;
      _fillPartyFieldsFromContract(profile: profile, contractors: contractors);
    });
  }

  /// Подставляет в блок «Стройка» адрес объекта по [Contract.objectId] (только просмотр).
  void _tryApplyObjectAddressToConstruction({
    required ObjectStatus status,
    required List<ObjectEntity> objects,
  }) {
    if (_constructionAddressApplied || !mounted) return;
    final objectId = widget.contract.objectId.trim();
    if (objectId.isEmpty) {
      _constructionAddressApplied = true;
      return;
    }

    ObjectEntity? found;
    for (final o in objects) {
      if (o.id == objectId) {
        found = o;
        break;
      }
    }

    if (found == null) {
      if (status == ObjectStatus.success) {
        _constructionAddressApplied = true;
      }
      return;
    }

    _constructionAddressApplied = true;
    final address = found.address.trim();
    if (address.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _constructionSiteDisplay = address;
      });
    });
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

  /// Подпись и значение стороны КС-2 без оформления поля ввода.
  Widget _readOnlyPartyValue({
    required ThemeData theme,
    required ColorScheme scheme,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final trimmed = value.trim();
    final display = trimmed.isEmpty ? '—' : trimmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: SelectableText(
              display,
              style: valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    height: 1.32,
                    fontSize: 14,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final companyId = widget.contract.companyId;

    final objectState = ref.watch(objectProvider);
    _tryApplyObjectAddressToConstruction(
      status: objectState.status,
      objects: objectState.objects,
    );

    final partiesAsync = ref.watch(ks2PartiesContextProvider(companyId));

    return partiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SelectableText.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            children: [
              const TextSpan(text: 'Не удалось загрузить данные для сторон КС-2: '),
              TextSpan(text: '$e'),
            ],
          ),
        ),
      ),
      data: (({CompanyProfile? profile, List<Contractor> contractors}) ctx) {
        final profile = ctx.profile;
        final contractors = ctx.contractors;
        _schedulePartyAutoFillIfNeeded(profile: profile, contractors: contractors);

        final noCardData = profile == null && contractors.isEmpty;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Унифицированная форма № КС-2. Заказчик, подрядчик, ОКПО, стройка (адрес объекта), объект (наименование), '
                'номер и дата договора подставляются из договора и справочников — эти поля только для просмотра.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Стороны и объект'),
              if (noCardData)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Не удалось подставить стороны из справочника — проверьте реквизиты компании и контрагента в карточках.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.tertiary.withValues(alpha: 0.95),
                      height: 1.35,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _readOnlyPartyValue(
                      theme: theme,
                      scheme: scheme,
                      label: 'Заказчик (наименование, адрес, телефон, факс)',
                      value: _customerRequisites,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: _readOnlyPartyValue(
                      theme: theme,
                      scheme: scheme,
                      label: 'ОКПО',
                      value: _customerOkpo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _readOnlyPartyValue(
                      theme: theme,
                      scheme: scheme,
                      label: 'Подрядчик (наименование, адрес, телефон, факс)',
                      value: _contractorRequisites,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: _readOnlyPartyValue(
                      theme: theme,
                      scheme: scheme,
                      label: 'ОКПО',
                      value: _contractorOkpo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _readOnlyPartyValue(
                theme: theme,
                scheme: scheme,
                label: 'Стройка (наименование, адрес)',
                value: _constructionSiteDisplay,
              ),
              const SizedBox(height: 12),
              _readOnlyPartyValue(
                theme: theme,
                scheme: scheme,
                label: 'Объект (наименование, адрес)',
                value: widget.contract.objectName?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Договор и доп. соглашения'),
              GTTextField(
                controller: _okdpController,
                labelText: 'Вид деятельности по ОКДП',
                prefixIcon: CupertinoIcons.square_list,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _readOnlyPartyValue(
                      theme: theme,
                      scheme: scheme,
                      label: 'Договор подряда (номер)',
                      value: widget.contract.number.trim(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _readOnlyPartyValue(
                      theme: theme,
                      scheme: scheme,
                      label: 'Дата договора',
                      value: formatRuDate(widget.contract.date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              _sectionTitle(theme, 'Реквизиты акта и отчётный период'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: GTTextField(
                      controller: _docNumberController,
                      labelText: 'Номер документа (акта)',
                      prefixIcon: CupertinoIcons.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: GTTextField(
                      controller: _docDateController,
                      labelText: 'Дата составления',
                      hintText: 'дд.мм.гггг',
                      prefixIcon: CupertinoIcons.calendar,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: GTTextField(
                      controller: _periodFromController,
                      labelText: 'Отчётный период — с',
                      hintText: 'дд.мм.гггг',
                      prefixIcon: CupertinoIcons.calendar_badge_plus,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: GTTextField(
                      controller: _periodToController,
                      labelText: 'Отчётный период — по',
                      hintText: 'дд.мм.гггг',
                      prefixIcon: CupertinoIcons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Сметная (договорная) стоимость и НДС'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: GTTextField(
                      controller: _estimateCostController,
                      labelText: 'Сметная (договорная) стоимость, ₽',
                      hintText: '0,00',
                      prefixIcon: CupertinoIcons.money_rubl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GTTextField(
                      controller: _vatRateController,
                      labelText: 'НДС, %',
                      hintText: '20',
                      prefixIcon: CupertinoIcons.percent,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GTTextField(
                      controller: _vatAmountController,
                      labelText: 'Сумма НДС, ₽',
                      hintText: '0,00',
                      prefixIcon: CupertinoIcons.equal_circle,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _sectionTitle(theme, 'Таблица работ (позиции)'),
              if (widget.positionsSection != null)
                widget.positionsSection!
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.18),
                    ),
                    color: scheme.surfaceContainerLow.withValues(alpha: 0.35),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),
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
      },
    );
  }
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
