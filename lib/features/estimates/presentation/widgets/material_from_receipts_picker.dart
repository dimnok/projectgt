import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/gt_text_field.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../providers/estimate_providers.dart';
import '../../../materials/presentation/providers/materials_providers.dart';
import '../../../materials/data/models/material_binding_model.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Модальное окно для выбора материала из накладных и привязки к сметной позиции.
class MaterialFromReceiptsPicker extends ConsumerStatefulWidget {
  /// Идентификатор сметной позиции.
  final String estimateId;

  /// Номер договора (если есть) для фильтрации материалов.
  final String? contractNumber;

  /// Название сметной позиции.
  final String estimateName;

  /// Нужно ли оборачивать в DesktopDialogContent/MobileBottomSheetContent.
  /// По умолчанию true.
  final bool useWrapper;

  /// Создает экземпляр виджета.
  const MaterialFromReceiptsPicker({
    super.key,
    required this.estimateId,
    required this.estimateName,
    this.contractNumber,
    this.useWrapper = true,
  });

  /// Показывает модальное окно выбора материала.
  ///
  /// Адаптируется под платформу: диалог на десктопе и bottom sheet на мобильных устройствах.
  static Future<void> show(
    BuildContext context, {
    required String estimateId,
    required String estimateName,
    String? contractNumber,
  }) async {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      return DesktopDialogContent.show(
        context,
        title: 'Выбор материала из накладных',
        scrollable: false,
        padding: EdgeInsets.zero,
        child: MaterialFromReceiptsPicker(
          estimateId: estimateId,
          estimateName: estimateName,
          contractNumber: contractNumber,
          useWrapper: false,
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (context) => MaterialFromReceiptsPicker(
          estimateId: estimateId,
          estimateName: estimateName,
          contractNumber: contractNumber,
        ),
      );
    }
  }

  @override
  ConsumerState<MaterialFromReceiptsPicker> createState() =>
      _MaterialFromReceiptsPickerState();
}

class _MaterialFromReceiptsPickerState
    extends ConsumerState<MaterialFromReceiptsPicker> {
  String _searchQuery = '';
  MaterialBindingModel? _selectedMaterial;
  bool _isLinking = false;
  bool _isUnlinking = false;
  bool _isKitMode = false;
  late final TextEditingController _multiplierController;

  @override
  void initState() {
    super.initState();
    _multiplierController = TextEditingController(text: '1.0');
  }

  @override
  void dispose() {
    _multiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final materialsAsync = ref.watch(
      materialBindingListProvider((
        contractNumber: widget.contractNumber,
        estimateId: widget.estimateId,
      )),
    );
    final estimateAsync = ref.watch(estimateProvider(widget.estimateId));

    final String estimateUnit = estimateAsync.when(
      data: (e) => e?.unit ?? '—',
      loading: () => '...',
      error: (_, __) => '?',
    );

    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GTSecondaryButton(
          text: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 16),
        GTPrimaryButton(
          text: _isKitMode ? 'Добавить в комплект' : 'Привязать',
          isLoading: _isLinking,
          onPressed: _selectedMaterial == null ? null : _handleLink,
        ),
      ],
    );

    final header = Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.03),
          theme.colorScheme.surface,
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ПРИВЯЗКА К ПОЗИЦИИ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          widget.estimateName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            height: 1.2,
                          ),
                        ),
                        _InfoTag(
                          text: estimateUnit,
                          theme: theme,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isKitMode ? 'КОМПЛЕКТ' : '1:1',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          color: _isKitMode
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 20,
                        width: 36,
                        child: Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: _isKitMode,
                            onChanged: (val) =>
                                setState(() => _isKitMode = val),
                            activeThumbColor: theme.colorScheme.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GTTextField(
            hintText: 'Поиск материала или накладной...',
            prefixIcon: Icons.search_rounded,
            borderRadius: 12,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ],
      ),
    );

    final content = Column(
      children: [
        header,
        Expanded(
          child: materialsAsync.when(
            data: (materials) {
              final filtered = materials.where((m) {
                final name = m.name.toLowerCase();
                final receipt = (m.receiptNumber ?? '').toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || receipt.contains(query);
              }).toList();

              // Сортировка: привязанные позиции первыми
              filtered.sort((a, b) {
                final aIsCurrent =
                    a.bindingStatus == MaterialBindingStatus.current;
                final bIsCurrent =
                    b.bindingStatus == MaterialBindingStatus.current;
                if (aIsCurrent && !bIsCurrent) return -1;
                if (!aIsCurrent && bIsCurrent) return 1;
                return 0;
              });

              if (filtered.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Материалы не найдены'),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const ClampingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected =
                      _selectedMaterial?.name == item.name &&
                      _selectedMaterial?.unit == item.unit;
                  final isShared =
                      item.bindingStatus == MaterialBindingStatus.shared ||
                      item.bindingStatus == MaterialBindingStatus.conflict;
                  final isCurrent =
                      item.bindingStatus == MaterialBindingStatus.current;
                  final bool isDisabled = isCurrent;

                  // Логика нормализации для сравнения единиц измерения
                  String normalize(String? unit) {
                    if (unit == null || unit == '—' || unit.isEmpty) {
                      return '';
                    }
                    return unit.trim().toLowerCase().replaceAll('.', '');
                  }

                  final String normalizedItemUnit = normalize(item.unit);
                  final String normalizedEstimateUnit = normalize(estimateUnit);

                  final bool unitMismatch =
                      normalizedItemUnit.isNotEmpty &&
                      normalizedEstimateUnit.isNotEmpty &&
                      normalizedItemUnit != normalizedEstimateUnit;

                  return Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isDisabled
                            ? null
                            : () {
                                if (isSelected) {
                                  // Повторный клик — снимаем выбор
                                  setState(() => _selectedMaterial = null);
                                } else {
                                  // Выбираем новую позицию
                                  _multiplierController.text = '1.0';
                                  setState(() => _selectedMaterial = item);
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                )
                              : (isDisabled
                                    ? theme.disabledColor.withValues(
                                        alpha: 0.02,
                                      )
                                    : null),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 14,
                                        color: isDisabled
                                            ? theme.disabledColor
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _InfoTag(
                                          text: item.unit ?? '—',
                                          theme: theme,
                                        ),
                                        if (item.receiptNumber != null &&
                                            item.receiptNumber!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          _InfoTag(
                                            text: '#${item.receiptNumber}',
                                            theme: theme,
                                            isSecondary: true,
                                          ),
                                        ],
                                        const Spacer(),
                                        if (isShared)
                                          Tooltip(
                                            message:
                                                'Также используется в:\n${item.linkedEstimateNames.join('\n')}',
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.link_rounded,
                                                  size: 12,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ОБЩИЙ',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (isCurrent)
                                          Text(
                                            'ПРИВЯЗАН',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isSelected && unitMismatch)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error
                                                .withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                size: 12,
                                                color: theme.colorScheme.error,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Ед. изм. не совпадают',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      theme.colorScheme.error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isCurrent && !isSelected)
                                IconButton(
                                  icon: const Icon(
                                    Icons.link_off_rounded,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: _isUnlinking
                                      ? null
                                      : () => _handleUnlink(item),
                                  tooltip: 'Отвязать материал',
                                ),
                              if (isSelected) ...[
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 75,
                                  child: TextField(
                                    controller: _multiplierController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [quantityFormatter()],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                      prefixText: '×',
                                      prefixStyle: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
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
                      const Divider(height: 1),
                    ],
                  );
                },
              );
            },
            loading: () => Center(
              child: Text(
                'ЗАГРУЗКА ДАННЫХ...',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'ОШИБКА: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!widget.useWrapper) {
      return Column(
        children: [
          Expanded(child: content),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: footer,
          ),
        ],
      );
    }

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: DesktopDialogContent(
          title: 'Выбор материала из накладных',
          footer: footer,
          scrollable: false,
          padding:
              EdgeInsets.zero, // Убираем внешний отступ, чтобы хедер прилегал
          child: content,
        ),
      );
    } else {
      return MobileBottomSheetContent(
        title: 'Выбор материала',
        footer: footer,
        scrollable: false,
        padding:
            EdgeInsets.zero, // Убираем внешний отступ, чтобы хедер прилегал
        child: content,
      );
    }
  }

  Future<void> _handleLink() async {
    if (_selectedMaterial == null) return;
    final multiplier = parseAmount(_multiplierController.text) ?? 1.0;

    setState(() => _isLinking = true);
    try {
      final repo = ref.read(materialsRepositoryProvider);
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      await repo.linkMaterialToEstimate(
        estimateId: widget.estimateId,
        aliasRaw: _selectedMaterial!.name,
        uomRaw: _selectedMaterial!.unit,
        companyId: activeCompanyId!,
        multiplier: multiplier,
      );
      ref.invalidate(
        materialBindingListProvider((
          contractNumber: widget.contractNumber,
          estimateId: widget.estimateId,
        )),
      );
      ref.invalidate(materialsGroupedListProvider);
      ref.invalidate(estimateCompletionByIdsProvider);
      if (mounted) {
        if (!_isKitMode) {
          Navigator.of(context).pop();
          SnackBarUtils.showSuccess(context, 'Материал успешно привязан');
        } else {
          SnackBarUtils.showSuccess(
            context,
            'Добавлено: ${_selectedMaterial!.name} (x$multiplier)',
          );
          setState(() {
            _selectedMaterial = null;
            _isLinking = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          e.toString().contains('unique')
              ? 'Этот материал уже привязан в рамках договора'
              : 'Ошибка привязки: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  Future<void> _handleUnlink(MaterialBindingModel item) async {
    if (item.aliasId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отвязать материал?'),
        content: Text(
          'Вы уверены, что хотите отвязать материал "${item.name}" от этой сметной позиции?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отвязать'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isUnlinking = true);
    try {
      final repo = ref.read(materialsRepositoryProvider);
      await repo.unlinkMaterialFromEstimate(item.aliasId!);
      ref.invalidate(
        materialBindingListProvider((
          contractNumber: widget.contractNumber,
          estimateId: widget.estimateId,
        )),
      );
      ref.invalidate(materialsGroupedListProvider);
      ref.invalidate(estimateCompletionByIdsProvider);
      if (mounted) SnackBarUtils.showSuccess(context, 'Материал отвязан');
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isUnlinking = false);
    }
  }
}

class _InfoTag extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final bool isSecondary;
  final bool isPrimary;

  const _InfoTag({
    required this.text,
    required this.theme,
    this.isSecondary = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isPrimary) {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isSecondary) {
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.secondary;
    } else {
      bgColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }
}
