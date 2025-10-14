import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/materials_mapping_providers.dart';
import '../../data/models/similar_estimate.dart';

/// Кнопка "Связь": открывает диалог со списком материалов (из модуля Материал)
/// для привязки алиасов к сметной позиции.
class MaterialsLinkButton extends ConsumerWidget {
  /// Идентификатор сметной строки, к которой выполняется привязка.
  final String estimateId;

  /// Количество уже связанных алиасов (визуальная индикация).
  final int aliasCount;

  /// Конструктор кнопки привязки материалов.
  /// Конструктор кнопки привязки материалов.
  const MaterialsLinkButton({
    super.key,
    required this.estimateId,
    required this.aliasCount,
  });

  /// Построение виджета кнопки привязки.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color bg = aliasCount > 0 ? Colors.green : Colors.red;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _openDialog(context, ref),
      minimumSize: const Size(0, 0),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Открывает диалог и обновляет список после закрытия.
  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => _MaterialsListDialog(estimateId: estimateId),
    );
    // После закрытия диалога — обновляем список через пагинатор
    ref.read(estimatesMappingPagerProvider.notifier).refresh();
  }
}

/// Диалог со списком материалов из модуля "Материал".
/// Пока MVP: просто список имен из таблицы `materials` с поиском.
class _MaterialsListDialog extends ConsumerStatefulWidget {
  final String estimateId;

  /// Конструктор диалога выбора материала.
  const _MaterialsListDialog({required this.estimateId});

  @override
  ConsumerState<_MaterialsListDialog> createState() =>
      _MaterialsListDialogState();
}

class _MaterialsListDialogState extends ConsumerState<_MaterialsListDialog> {
  String _query = '';
  bool _loading = false;
  List<Map<String, dynamic>> _items = const [];
  bool _saving = false;
  String? _contractNumber;
  String? _estimateName;
  String? _estimateUnit;
  bool _initialized = false;
  bool _isKitMode = false; // Режим комплекта
  final Map<String, TextEditingController> _multiplierControllers =
      {}; // Контроллеры для коэффициентов

  @override
  void initState() {
    super.initState();
    _initContract();
  }

  /// Получаем номер договора и название сметной позиции при инициализации
  Future<void> _initContract() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final estimateRes = await client
          .from('estimates')
          .select('name, unit, contracts!inner(number)')
          .eq('id', widget.estimateId)
          .maybeSingle();

      if (estimateRes != null && estimateRes['contracts'] != null) {
        _contractNumber = estimateRes['contracts']['number']?.toString();
        _estimateName = estimateRes['name']?.toString();
        _estimateUnit = estimateRes['unit']?.toString();

        // Автоматически запускаем поиск по названию сметной позиции
        final estimateName = _estimateName ?? '';
        if (estimateName.length >= 2) {
          // Извлекаем ключевые слова из названия (первые 2-3 слова)
          final words = estimateName.split(' ');
          final searchQuery = words.take(3).join(' ').toLowerCase();

          if (mounted) {
            setState(() {
              _initialized = true;
              _query = searchQuery;
            });
            // Запускаем поиск сразу
            _search(searchQuery);
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  /// Поиск материалов с умной сортировкой по схожести
  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _items = []);
      return;
    }

    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);

      if (_contractNumber == null || _contractNumber!.isEmpty) {
        if (mounted) setState(() => _items = []);
        return;
      }

      final searchQuery = query.trim().toLowerCase();

      // Пытаемся использовать RPC функцию с trigram similarity
      try {
        final rows = await client.rpc(
          'search_materials_by_similarity',
          params: {
            'search_query': searchQuery,
            'contract_num': _contractNumber!,
          },
        );

        final result = (rows as List)
            .map((e) => {
                  'id': e['id']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                  'unit': e['unit']?.toString(),
                  'receipt_number': e['receipt_number']?.toString(),
                })
            .toList();

        if (mounted) {
          setState(() => _items = result);
        }
      } catch (rpcError) {
        // Fallback на простой ILIKE если функция не создана
        final rows = await client
            .from('v_materials_with_usage')
            .select('id, name, unit, receipt_number')
            .eq('contract_number', _contractNumber!)
            .isFilter('estimate_id', null)
            .ilike('name', '%$searchQuery%')
            .order('name', ascending: true)
            .limit(500);

        final result = (rows as List)
            .map((e) => {
                  'id': e['id']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                  'unit': e['unit']?.toString(),
                  'receipt_number': e['receipt_number']?.toString(),
                })
            .toList();

        if (mounted) {
          setState(() => _items = result);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Выберите материал из накладных'),
          if (_estimateName != null && _estimateName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.08),
                    Colors.blue.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.bookmark_outline,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привязка к:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _estimateName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_estimateUnit != null && _estimateUnit!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _estimateUnit!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Переключатель режима: обычная связь / комплект
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isKitMode
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isKitMode
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isKitMode ? Icons.category : Icons.link,
                    size: 20,
                    color: _isKitMode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isKitMode
                          ? 'Режим комплекта: несколько материалов на 1 работу'
                          : 'Обычная связь: 1 материал на 1 работу',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _isKitMode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isKitMode,
                    onChanged: (value) {
                      setState(() {
                        _isKitMode = value;
                        _query = ''; // Сбрасываем поиск
                        _items = []; // Очищаем список
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              controller: TextEditingController(text: _query)
                ..selection = TextSelection.collapsed(offset: _query.length),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Введите минимум 2 символа для поиска...',
              ),
              onChanged: (v) {
                setState(() => _query = v);
                _search(v);
              },
            ),
            const SizedBox(height: 12),
            if (!_initialized)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_saving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_query.trim().length < 2)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.search, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Введите минимум 2 символа для поиска',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Материалы не найдены',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'Найдено: ${_items.length} ${_items.length >= 500 ? '(показаны первые 500)' : 'материалов'}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          final materialId =
                              it['id']?.toString() ?? index.toString();

                          // Создаём контроллер для каждого материала
                          if (!_multiplierControllers.containsKey(materialId)) {
                            _multiplierControllers[materialId] =
                                TextEditingController(text: '1');
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Основная информация
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it['name'] ?? '—',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          // Единица измерения
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              it['unit'] ?? '—',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Номер накладной
                                          Text(
                                            '№ ${it['receipt_number'] ?? '?'}',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              color:
                                                  theme.colorScheme.secondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Поле ввода коэффициента
                                SizedBox(
                                  width: 70,
                                  child: TextField(
                                    controller:
                                        _multiplierControllers[materialId],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      prefixText: '×',
                                      prefixStyle:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: Colors.blue
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: Colors.blue
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Кнопка добавления
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _linkMaterial(it),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        itemCount: _items.length,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  /// Привязывает выбранный материал как алиас к сметной позиции.
  /// В режиме комплекта (_isKitMode) диалог не закрывается - можно добавить несколько материалов.
  Future<void> _linkMaterial(Map<String, dynamic> it) async {
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final String alias = (it['name']?.toString() ?? '').trim();
      final String? uom = it['unit']?.toString();
      final materialId = it['id']?.toString() ?? '';

      if (alias.isEmpty) {
        setState(() => _saving = false);
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      // Получаем коэффициент из поля ввода
      final multiplierText = _multiplierControllers[materialId]?.text ?? '1';
      final double multiplier =
          double.tryParse(multiplierText.replaceAll(',', '.')) ?? 1.0;

      if (_isKitMode) {
        // РЕЖИМ КОМПЛЕКТА: запрашиваем количество через диалог
        final double? qtyPerKit =
            await _showQuantityDialog(context, alias, uom);

        if (qtyPerKit == null) {
          setState(() => _saving = false);
          return;
        }

        try {
          await client.rpc('add_kit_component', params: {
            'p_parent_estimate_id': widget.estimateId,
            'p_material_name': alias,
            'p_material_unit': uom ?? 'шт',
            'p_qty_per_kit': qtyPerKit,
            'p_alias_raw': alias,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $alias ($qtyPerKit ${uom ?? "шт"})'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Удаляем из списка и контроллер, но диалог НЕ закрываем
        setState(() {
          _items.removeWhere((e) => e['id'] == it['id']);
          _multiplierControllers.remove(materialId)?.dispose();
        });
      } else {
        // ОБЫЧНЫЙ РЕЖИМ С УМНОЙ ПРИВЯЗКОЙ:
        // 1. Ищем похожие позиции через PostgreSQL функцию
        List<String> targetEstimateIds = [widget.estimateId];

        // Проверяем, нужно ли искать похожие позиции
        if (_contractNumber != null &&
            _contractNumber!.isNotEmpty &&
            _estimateName != null &&
            _estimateName!.isNotEmpty &&
            uom != null &&
            uom.isNotEmpty) {
          // Получаем contract_id
          final contractRes = await client
              .from('contracts')
              .select('id')
              .eq('number', _contractNumber!)
              .maybeSingle();

          if (contractRes != null) {
            final contractId = contractRes['id']?.toString();

            if (contractId != null && contractId.isNotEmpty) {
              // Нормализуем единицу измерения (добавляем точку если её нет)
              // Проверяем последний символ - если не точка и не пустая строка, добавляем точку
              String normalizedUnit = uom;
              if (uom.isNotEmpty && !uom.endsWith('.') && !uom.endsWith(')')) {
                // Добавляем точку только для коротких единиц (не для составных типа "кв.м")
                if (!uom.contains('.') && uom.length <= 6) {
                  normalizedUnit = '$uom.';
                }
              }

              // Ищем похожие позиции
              final similarEstimates = await _findSimilarEstimates(
                contractId: contractId,
                estimateName: _estimateName!,
                estimateUnit: normalizedUnit,
                currentEstimateId: widget.estimateId,
              );

              // Проверяем mounted после async операции
              if (!mounted) {
                setState(() => _saving = false);
                return;
              }

              // Если найдены похожие позиции - показываем диалог выбора
              if (similarEstimates.isNotEmpty) {
                final selectedIds = await _showSimilarEstimatesDialog(
                  context: context,
                  currentEstimateId: widget.estimateId,
                  similarEstimates: similarEstimates,
                );

                // Пользователь отменил выбор
                if (selectedIds == null) {
                  setState(() => _saving = false);
                  return;
                }

                // Используем выбранные ID
                targetEstimateIds = selectedIds;
              }
            }
          }
        }

        // 2. Массовая вставка алиасов для всех выбранных позиций
        await _linkMaterialToMultiple(
          material: it,
          estimateIds: targetEstimateIds,
          multiplier: multiplier,
        );

        // 3. Удаляем материал из списка и закрываем диалог
        setState(() {
          _items.removeWhere((e) => e['id'] == it['id']);
          _multiplierControllers.remove(materialId)?.dispose();
        });

        if (!mounted) return;
        Navigator.of(context).pop(it);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Поиск похожих сметных позиций через PostgreSQL функцию.
  ///
  /// Возвращает список позиций с similarity >= 0.4 (40%).
  Future<List<SimilarEstimate>> _findSimilarEstimates({
    required String contractId,
    required String estimateName,
    required String estimateUnit,
    required String currentEstimateId,
  }) async {
    try {
      final client = ref.read(supabaseClientProvider);

      final response = await client.rpc(
        'find_similar_estimates',
        params: {
          'p_contract_id': contractId,
          'p_estimate_name': estimateName,
          'p_unit': estimateUnit,
          'p_current_estimate_id': currentEstimateId,
          'p_min_similarity': 0.4, // Порог 40% схожести
        },
      );

      if (response == null) {
        return [];
      }

      final results = (response as List)
          .map((row) => SimilarEstimate.fromMap(row as Map<String, dynamic>))
          .toList();

      return results;
    } catch (e) {
      // Fallback: если функция не создана или ошибка - возвращаем пустой список
      return [];
    }
  }

  /// Диалог для выбора похожих сметных позиций.
  ///
  /// Показывает список чекбоксов с похожими позициями.
  /// Возвращает список выбранных estimate_id (включая текущую позицию).
  Future<List<String>?> _showSimilarEstimatesDialog({
    required BuildContext context,
    required String currentEstimateId,
    required List<SimilarEstimate> similarEstimates,
  }) async {
    // По умолчанию все похожие позиции выбраны
    final selected = similarEstimates.map((e) => e.id).toSet();

    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Найдены похожие работы'),
                  ),
                ],
              ),
              content: SizedBox(
                width: 650,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Система нашла похожие работы в других системах. Вы можете привязать материал ко всем сразу.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Привязать материал к:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: similarEstimates.length,
                        itemBuilder: (context, index) {
                          final estimate = similarEstimates[index];
                          final isSelected = selected.contains(estimate.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selected.add(estimate.id);
                                } else {
                                  selected.remove(estimate.id);
                                }
                              });
                            },
                            title: Text(
                              estimate.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${estimate.system} → ${estimate.subsystem}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Схожесть: ${(estimate.similarityScore * 100).toStringAsFixed(0)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            dense: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop([currentEstimateId]),
                  child: const Text('Только к текущей'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                            [currentEstimateId, ...selected],
                          ),
                  child: Text('Привязать ко всем (${selected.length + 1})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Массовая вставка алиасов для нескольких сметных позиций.
  ///
  /// Создаёт записи в таблице material_aliases для каждой позиции.
  Future<void> _linkMaterialToMultiple({
    required Map<String, dynamic> material,
    required List<String> estimateIds,
    required double multiplier,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final alias = material['name']?.toString() ?? '';
    final uom = material['unit']?.toString();

    try {
      // Массовая вставка
      await client.from('material_aliases').insert(
            estimateIds
                .map((estimateId) => {
                      'estimate_id': estimateId,
                      'alias_raw': alias,
                      'uom_raw': uom,
                      'multiplier_to_estimate': multiplier,
                    })
                .toList(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Материал привязан к ${estimateIds.length} ${estimateIds.length == 1 ? 'позиции' : estimateIds.length < 5 ? 'позициям' : 'позициям'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка привязки: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Диалог для ввода количества материала в комплекте (для режима комплекта).
  Future<double?> _showQuantityDialog(
      BuildContext context, String materialName, String? materialUnit) async {
    final controller = TextEditingController(text: '1.0');
    final formKey = GlobalKey<FormState>();

    return showDialog<double>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Количество в комплекте'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Материал:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        materialName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Единица: ${materialUnit ?? "шт"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Количество на 1 работу',
                    hintText: '1.0',
                    helperText:
                        'Сколько ${materialUnit ?? "шт"} нужно на 1 ед. работы?',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите количество';
                    }
                    final num = double.tryParse(value.trim());
                    if (num == null) {
                      return 'Введите число';
                    }
                    if (num <= 0) {
                      return 'Количество должно быть > 0';
                    }
                    if (num > 1000000) {
                      return 'Количество слишком большое';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Пример комплекта:',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'На 1 "Монтаж мачты" нужно:\n• 10 шайб\n• 5 гаек\n• 5 болтов\n• 10 м троса',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final value = double.parse(controller.text.trim());
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Очищаем все контроллеры при закрытии диалога
    for (final controller in _multiplierControllers.values) {
      controller.dispose();
    }
    _multiplierControllers.clear();
    super.dispose();
  }
}
