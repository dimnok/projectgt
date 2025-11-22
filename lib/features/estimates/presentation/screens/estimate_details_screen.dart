import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/estimate.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/estimate_item_card.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';

/// Экран для отображения детальной информации о смете.
///
/// Показывает таблицу позиций сметы с использованием PlutoGrid.
/// Добавлена возможность редактирования, добавления и удаления позиций.
class EstimateDetailsScreen extends ConsumerStatefulWidget {
  /// Название сметы для отображения.
  final String? estimateTitle;

  /// Создаёт экран деталей сметы.
  const EstimateDetailsScreen({super.key, this.estimateTitle});

  @override
  ConsumerState<EstimateDetailsScreen> createState() =>
      _EstimateDetailsScreenState();
}

/// Состояние для [EstimateDetailsScreen].
class _EstimateDetailsScreenState extends ConsumerState<EstimateDetailsScreen> {
  /// Колонки таблицы PlutoGrid.
  late List<PlutoColumn> columns;

  /// Строки таблицы PlutoGrid.
  late List<PlutoRow> rows;

  /// Контроллер состояния таблицы
  PlutoGridStateManager? stateManager;

  /// Контроллер для текста поиска
  final TextEditingController _searchController = TextEditingController();

  /// Критерий сортировки для мобильного вида
  String _sortCriterion = 'number';

  /// Порядок сортировки (по возрастанию/убыванию)
  bool _sortAscending = true;

  /// Генерация идентификаторов для новых строк
  final Uuid _uuid = const Uuid();

  /// Список уникальных систем из смет
  List<String> _systems = [];

  /// Список уникальных подсистем из смет
  List<String> _subsystems = [];

  /// Список уникальных единиц измерения из смет
  List<String> _units = [];

  /// Индикатор загрузки систем
  bool _systemsLoading = false;

  /// Индикатор загрузки подсистем
  bool _subsystemsLoading = false;

  /// Индикатор загрузки единиц измерения
  bool _unitsLoading = false;

  /// Контроллер прокрутки для списка позиций
  final ScrollController _scrollController = ScrollController();

  /// Флаг видимости верхнего блока
  bool _isHeaderVisible = true;

  /// Предыдущая позиция прокрутки
  double _previousScrollPosition = 0;

  /// Минимальное смещение для срабатывания скрытия/показа
  final double _scrollThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    _loadLookupData();

    // Добавляем слушатель прокрутки
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Удаляем слушатель и очищаем контроллер прокрутки
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// Слушатель прокрутки для управления видимостью верхнего блока
  void _scrollListener() {
    // Проверяем, что у контроллера есть позиция
    if (!_scrollController.hasClients) return;

    // Получаем текущую позицию прокрутки
    final currentPosition = _scrollController.position.pixels;

    // Определяем направление прокрутки
    final isScrollingDown = currentPosition > _previousScrollPosition;

    // Проверяем, превышает ли разница порог
    if ((currentPosition - _previousScrollPosition).abs() > _scrollThreshold) {
      // Обновляем видимость верхнего блока в зависимости от направления
      if (isScrollingDown && _isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      } else if (!isScrollingDown &&
          !_isHeaderVisible &&
          currentPosition < 100) {
        setState(() {
          _isHeaderVisible = true;
        });
      }

      // Обновляем предыдущую позицию
      _previousScrollPosition = currentPosition;
    }
  }

  /// Загружает справочные данные (списки уникальных значений)
  Future<void> _loadLookupData() async {
    setState(() {
      _systemsLoading = true;
      _subsystemsLoading = true;
      _unitsLoading = true;
    });

    try {
      final estimateRepo = ref.read(estimateRepositoryProvider);
      final systems =
          await estimateRepo.getSystems(estimateTitle: widget.estimateTitle);
      final subsystems =
          await estimateRepo.getSubsystems(estimateTitle: widget.estimateTitle);
      final units =
          await estimateRepo.getUnits(estimateTitle: widget.estimateTitle);

      if (!mounted) return;

      setState(() {
        _systems = systems;
        _subsystems = subsystems;
        _units = units;
        _systemsLoading = false;
        _subsystemsLoading = false;
        _unitsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _systemsLoading = false;
        _subsystemsLoading = false;
        _unitsLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке справочных данных: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Фильтрует и сортирует список позиций сметы
  List<Estimate> _filterAndSortItems(List<Estimate> items) {
    // Фильтрация по поисковому запросу
    final searchQuery = _searchController.text.toLowerCase().trim();
    var filteredItems = items;

    if (searchQuery.isNotEmpty) {
      filteredItems = items.where((item) {
        return item.name.toLowerCase().contains(searchQuery) ||
            item.system.toLowerCase().contains(searchQuery) ||
            item.subsystem.toLowerCase().contains(searchQuery) ||
            item.article.toLowerCase().contains(searchQuery) ||
            item.manufacturer.toLowerCase().contains(searchQuery) ||
            item.number.toString().contains(searchQuery);
      }).toList();
    }

    // Сортировка по выбранному критерию
    filteredItems.sort((a, b) {
      int result = 0;

      switch (_sortCriterion) {
        case 'number':
          // Интеллектуальная сортировка номеров (с поддержкой смешанных типов)
          // Если оба номера числовые, сравниваем их как числа
          final aIsNumeric = RegExp(r'^\d+(\.\d+)?$').hasMatch(a.number);
          final bIsNumeric = RegExp(r'^\d+(\.\d+)?$').hasMatch(b.number);

          if (aIsNumeric && bIsNumeric) {
            try {
              final numA = double.parse(a.number.replaceAll(',', '.'));
              final numB = double.parse(b.number.replaceAll(',', '.'));
              result = numA.compareTo(numB);
            } catch (e) {
              // В случае ошибки используем строковое сравнение
              result = a.number.compareTo(b.number);
            }
          } else if (aIsNumeric) {
            // Числовые номера идут перед нечисловыми
            result = -1;
          } else if (bIsNumeric) {
            // Числовые номера идут перед нечисловыми
            result = 1;
          } else {
            // Если оба нечисловые, используем обычное строковое сравнение
            result = a.number.compareTo(b.number);
          }
          break;
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'system':
          result = a.system.compareTo(b.system);
          break;
        case 'price':
          result = a.price.compareTo(b.price);
          break;
        case 'total':
          result = a.total.compareTo(b.total);
          break;
        default:
          // Интеллектуальная сортировка по умолчанию
          final aIsNumeric = RegExp(r'^\d+(\.\d+)?$').hasMatch(a.number);
          final bIsNumeric = RegExp(r'^\d+(\.\d+)?$').hasMatch(b.number);

          if (aIsNumeric && bIsNumeric) {
            try {
              final numA = double.parse(a.number.replaceAll(',', '.'));
              final numB = double.parse(b.number.replaceAll(',', '.'));
              result = numA.compareTo(numB);
            } catch (e) {
              result = a.number.compareTo(b.number);
            }
          } else if (aIsNumeric) {
            result = -1;
          } else if (bIsNumeric) {
            result = 1;
          } else {
            result = a.number.compareTo(b.number);
          }
      }

      return _sortAscending ? result : -result;
    });

    return filteredItems;
  }

  /// Показывает диалог выбора критерия сортировки
  void _showSortDialog(BuildContext context) {
    final options = [
      {'value': 'number', 'label': 'По номеру'},
      {'value': 'name', 'label': 'По наименованию'},
      {'value': 'system', 'label': 'По системе'},
      {'value': 'price', 'label': 'По цене'},
      {'value': 'total', 'label': 'По сумме'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сортировка'),
        content: RadioGroup<String>(
          groupValue: _sortCriterion,
          onChanged: (value) {
            if (value == _sortCriterion) {
              // Если выбран тот же критерий, меняем порядок сортировки
              setState(() {
                _sortAscending = !_sortAscending;
              });
            } else {
              // Если выбран новый критерий, устанавливаем его и сортируем по возрастанию
              setState(() {
                _sortCriterion = value!;
                _sortAscending = true;
              });
            }
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...options.map((option) => RadioListTile<String>(
                    title: Text(option['label'] as String),
                    value: option['value'] as String,
                    secondary: _sortCriterion == option['value']
                        ? Icon(_sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward)
                        : null,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  /// Отображает диалог добавления/редактирования позиции сметы
  void _showItemDialog(BuildContext context, [Estimate? estimate]) {
    final isEditing = estimate != null;
    final itemTitle =
        isEditing ? 'Редактирование позиции' : 'Добавление позиции';

    final systemController =
        TextEditingController(text: isEditing ? estimate.system : '');
    final subsystemController =
        TextEditingController(text: isEditing ? estimate.subsystem : '');
    final numberController = TextEditingController(
        text: isEditing ? estimate.number.toString() : '');
    final nameController =
        TextEditingController(text: isEditing ? estimate.name : '');
    final articleController =
        TextEditingController(text: isEditing ? estimate.article : '');
    final manufacturerController =
        TextEditingController(text: isEditing ? estimate.manufacturer : '');
    final unitController =
        TextEditingController(text: isEditing ? estimate.unit : '');
    final quantityController = TextEditingController(
        text: isEditing ? estimate.quantity.toString() : '');
    final priceController =
        TextEditingController(text: isEditing ? estimate.price.toString() : '');

    final formKey = GlobalKey<FormState>();

    // Получаем текущие элементы сметы
    final state = ref.read(estimateNotifierProvider);
    final currentItems = state.estimates
        .where((e) => e.estimateTitle == widget.estimateTitle)
        .toList();

    // Определяем objectId и contractId от существующих записей или от переданной записи
    final objectId = isEditing
        ? estimate.objectId
        : (currentItems.isNotEmpty ? currentItems.first.objectId : null);
    final contractId = isEditing
        ? estimate.contractId
        : (currentItems.isNotEmpty ? currentItems.first.contractId : null);

    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            kToolbarHeight,
      ),
      builder: (context) {
        Widget modalContent = Container(
          margin: isLargeScreen ? const EdgeInsets.only(top: 48) : null,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Заголовок и кнопка закрытия
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  itemTitle,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                    foregroundColor: Colors.red),
                                onPressed: () => context.pop(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),

                        // Основная информация
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 51),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Основная информация',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                // Система
                                _systemsLoading
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      )
                                    : TypeAheadField<String>(
                                        controller: systemController,
                                        suggestionsCallback: (pattern) {
                                          return _systems
                                              .where((s) => s
                                                  .toLowerCase()
                                                  .contains(
                                                      pattern.toLowerCase()))
                                              .toList();
                                        },
                                        builder:
                                            (context, controller, focusNode) {
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'Система *',
                                              hintText:
                                                  'Выберите или введите систему',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (v) =>
                                                v == null || v.trim().isEmpty
                                                    ? 'Обязательное поле'
                                                    : null,
                                          );
                                        },
                                        itemBuilder: (context, suggestion) {
                                          return ListTile(
                                            title: Text(suggestion),
                                          );
                                        },
                                        onSelected: (suggestion) {
                                          setState(() {
                                            systemController.text = suggestion;
                                          });
                                        },
                                        emptyBuilder: (context) {
                                          final input =
                                              systemController.text.trim();
                                          if (input.isEmpty) {
                                            return const SizedBox();
                                          }
                                          return ListTile(
                                            title: Text(
                                                'Добавить новую систему: "$input"'),
                                            onTap: () {
                                              setState(() {
                                                systemController.text = input;
                                              });
                                              FocusScope.of(context).unfocus();
                                            },
                                          );
                                        },
                                      ),
                                const SizedBox(height: 16),
                                // Подсистема
                                _subsystemsLoading
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      )
                                    : TypeAheadField<String>(
                                        controller: subsystemController,
                                        suggestionsCallback: (pattern) {
                                          return _subsystems
                                              .where((s) => s
                                                  .toLowerCase()
                                                  .contains(
                                                      pattern.toLowerCase()))
                                              .toList();
                                        },
                                        builder:
                                            (context, controller, focusNode) {
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'Подсистема *',
                                              hintText:
                                                  'Выберите или введите подсистему',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (v) =>
                                                v == null || v.trim().isEmpty
                                                    ? 'Обязательное поле'
                                                    : null,
                                          );
                                        },
                                        itemBuilder: (context, suggestion) {
                                          return ListTile(
                                            title: Text(suggestion),
                                          );
                                        },
                                        onSelected: (suggestion) {
                                          setState(() {
                                            subsystemController.text =
                                                suggestion;
                                          });
                                        },
                                        emptyBuilder: (context) {
                                          final input =
                                              subsystemController.text.trim();
                                          if (input.isEmpty) {
                                            return const SizedBox();
                                          }
                                          return ListTile(
                                            title: Text(
                                                'Добавить новую подсистему: "$input"'),
                                            onTap: () {
                                              setState(() {
                                                subsystemController.text =
                                                    input;
                                              });
                                              FocusScope.of(context).unfocus();
                                            },
                                          );
                                        },
                                      ),
                                const SizedBox(height: 16),
                                // Номер
                                TextFormField(
                                  controller: numberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Номер *',
                                    hintText: 'Введите порядковый номер',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Обязательное поле'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                // Наименование
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Наименование *',
                                    hintText: 'Введите наименование позиции',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Обязательное поле'
                                          : null,
                                  maxLines: null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Техническая информация
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 51),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Техническая информация',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                // Артикул
                                TextFormField(
                                  controller: articleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Артикул',
                                    hintText: 'Введите артикул',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Производитель
                                TextFormField(
                                  controller: manufacturerController,
                                  decoration: const InputDecoration(
                                    labelText: 'Производитель',
                                    hintText: 'Введите производителя',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Единица измерения
                                _unitsLoading
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      )
                                    : TypeAheadField<String>(
                                        controller: unitController,
                                        suggestionsCallback: (pattern) {
                                          return _units
                                              .where((u) => u
                                                  .toLowerCase()
                                                  .contains(
                                                      pattern.toLowerCase()))
                                              .toList();
                                        },
                                        builder:
                                            (context, controller, focusNode) {
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'Единица измерения *',
                                              hintText:
                                                  'Выберите или введите единицу измерения',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (v) =>
                                                v == null || v.trim().isEmpty
                                                    ? 'Обязательное поле'
                                                    : null,
                                          );
                                        },
                                        itemBuilder: (context, suggestion) {
                                          return ListTile(
                                            title: Text(suggestion),
                                          );
                                        },
                                        onSelected: (suggestion) {
                                          setState(() {
                                            unitController.text = suggestion;
                                          });
                                        },
                                        emptyBuilder: (context) {
                                          final input =
                                              unitController.text.trim();
                                          if (input.isEmpty) {
                                            return const SizedBox();
                                          }
                                          return ListTile(
                                            title: Text(
                                                'Добавить новую единицу измерения: "$input"'),
                                            onTap: () {
                                              setState(() {
                                                unitController.text = input;
                                              });
                                              FocusScope.of(context).unfocus();
                                            },
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ценовая информация
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 51),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ценовая информация',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                // Количество
                                TextFormField(
                                  controller: quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Количество',
                                    hintText: 'Введите количество',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      // Возвращаем null вместо ошибки, поле необязательное
                                      return null;
                                    }
                                    try {
                                      double.parse(v.replaceAll(',', '.'));
                                    } catch (e) {
                                      return 'Введите число';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Цена
                                TextFormField(
                                  controller: priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Цена за единицу',
                                    hintText: 'Введите цену',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      // Возвращаем null вместо ошибки, поле необязательное
                                      return null;
                                    }
                                    try {
                                      double.parse(v.replaceAll(',', '.'));
                                    } catch (e) {
                                      return 'Введите число';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Кнопки управления
                        Row(
                          children: [
                            // Кнопка Отмена
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Отмена'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Кнопка Сохранить
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final quantity = double.parse(
                                        quantityController.text
                                            .replaceAll(',', '.'));
                                    final price = double.parse(priceController
                                        .text
                                        .replaceAll(',', '.'));

                                    final updatedEstimate = Estimate(
                                      id: isEditing ? estimate.id : _uuid.v4(),
                                      system: systemController.text,
                                      subsystem: subsystemController.text,
                                      number: numberController.text,
                                      name: nameController.text,
                                      article: articleController.text.trim(),
                                      manufacturer:
                                          manufacturerController.text.trim(),
                                      unit: unitController.text,
                                      quantity: quantity,
                                      price: price,
                                      total: quantity * price,
                                      estimateTitle: widget.estimateTitle,
                                      objectId: objectId,
                                      contractId: contractId,
                                    );

                                    if (isEditing) {
                                      _updateEstimateItem(updatedEstimate);
                                    } else {
                                      _addEstimateItem(updatedEstimate);
                                    }

                                    if (!context.mounted) return;
                                    context.pop();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                child:
                                    Text(isEditing ? 'Сохранить' : 'Добавить'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        if (isLargeScreen) {
          return Center(
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 220),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                    ),
                    child: modalContent,
                  ),
                ),
              ),
            ),
          );
        } else {
          return modalContent;
        }
      },
    );
  }

  /// Добавляет новую позицию в смету
  void _addEstimateItem(Estimate estimate) async {
    final notifier = ref.read(estimateNotifierProvider.notifier);
    await notifier.addEstimate(estimate);
  }

  /// Обновляет существующую позицию сметы
  void _updateEstimateItem(Estimate estimate) async {
    final notifier = ref.read(estimateNotifierProvider.notifier);
    await notifier.updateEstimate(estimate);
  }

  /// Удаляет позицию из сметы с подтверждением
  void _delete(String id) {
    CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удаление позиции',
      message: 'Вы действительно хотите удалить эту позицию?',
      onConfirm: () {
        ref.read(estimateNotifierProvider.notifier).deleteEstimate(id);
      },
    );
  }

  /// Дублирует позицию сметы с подтверждением
  void _duplicateItem(Estimate estimate) {
    // Если мы в мобильном режиме со свайпом, не показываем диалог подтверждения
    final isSwipeAction = ModalRoute.of(context)?.isCurrent != true;

    if (isSwipeAction) {
      _createDuplicate(estimate);
      return;
    }

    CupertinoDialogs.showDuplicateConfirmDialog<bool>(
      context: context,
      title: 'Дублирование позиции',
      message:
          'Вы действительно хотите создать дубликат позиции №${estimate.number}?',
      onConfirm: () {
        _createDuplicate(estimate);
      },
    );
  }

  /// Создает дубликат записи с новым номером
  void _createDuplicate(Estimate estimate) {
    // Создаем новый id и интеллектуально обрабатываем номер для дубликата
    String newNumber = estimate.number;

    // Целое число - просто увеличиваем на 1
    if (RegExp(r'^\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = int.parse(estimate.number);
        newNumber = (numValue + 1).toString();
      } catch (e) {
        newNumber = "${estimate.number}-копия";
      }
    }
    // Десятичное число с точкой (например, 10.1)
    else if (RegExp(r'^\d+\.\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = double.parse(estimate.number);
        newNumber = (numValue + 0.1).toStringAsFixed(1);
      } catch (e) {
        newNumber = "${estimate.number}-копия";
      }
    }
    // Десятичное число с запятой (например, 10,1)
    else if (RegExp(r'^\d+,\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = double.parse(estimate.number.replaceAll(',', '.'));
        newNumber = (numValue + 0.1).toStringAsFixed(1).replaceAll('.', ',');
      } catch (e) {
        newNumber = "${estimate.number}-копия";
      }
    }
    // Номер в формате [буква]-[число] (например, д-3)
    else if (RegExp(r'^([a-zA-Zа-яА-Я]+)-(\d+)$').hasMatch(estimate.number)) {
      final match =
          RegExp(r'^([a-zA-Zа-яА-Я]+)-(\d+)$').firstMatch(estimate.number);
      if (match != null) {
        final prefix = match.group(1);
        final numVal = int.parse(match.group(2)!);
        newNumber = "$prefix-${numVal + 1}";
      } else {
        newNumber = "${estimate.number}-копия";
      }
    }
    // Для всех остальных форматов добавляем "-копия"
    else {
      newNumber = "${estimate.number}-копия";
    }

    final newItem = estimate.copyWith(
      id: _uuid.v4(),
      number: newNumber,
    );
    ref.read(estimateNotifierProvider.notifier).addEstimate(newItem);
  }

  void _buildTable(List<Estimate> items, double containerWidth) {
    final nameColumnWidth = containerWidth * 0.4;
    const otherColumnCount = 9;
    final otherColumnWidth = (containerWidth * 0.6) / otherColumnCount;
    final moneyFormat = NumberFormat('###,##0.00', 'ru_RU');
    columns = [
      PlutoColumn(
          title: 'Система',
          field: 'system',
          type: PlutoColumnType.text(),
          width: otherColumnWidth,
          titleTextAlign: PlutoColumnTextAlign.center),
      PlutoColumn(
          title: 'Подсистема',
          field: 'subsystem',
          type: PlutoColumnType.text(),
          width: otherColumnWidth,
          titleTextAlign: PlutoColumnTextAlign.center),
      PlutoColumn(
        title: '№',
        field: 'number',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Наименование',
        field: 'name',
        type: PlutoColumnType.text(),
        width: nameColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: null,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Артикул',
        field: 'article',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Производитель',
        field: 'manufacturer',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Ед. изм.',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Количество',
        field: 'quantity',
        type: PlutoColumnType.number(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Цена',
        field: 'price',
        type: PlutoColumnType.number(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;
          final formatted = value is num
              ? moneyFormat.format(value)
              : (value?.toString() ?? '');
          return Text(
            formatted,
            textAlign: TextAlign.right,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Colors.green,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Сумма',
        field: 'total',
        type: PlutoColumnType.number(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;
          final formatted = value is num
              ? moneyFormat.format(value)
              : (value?.toString() ?? '');
          return Text(
            formatted,
            textAlign: TextAlign.right,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Действия',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (rendererContext) {
          final rowData = rendererContext.row;
          final itemId = rowData.cells['id']!.value.toString();
          final itemData = items.firstWhere((e) => e.id == itemId);
          final theme = Theme.of(context);

          return ActionButton(
            onTap: (details) => _showActionMenu(
                context, details.globalPosition, itemData, itemId),
            theme: theme,
          );
        },
      ),
    ];
    rows = items
        .map((e) => PlutoRow(cells: {
              'id': PlutoCell(value: e.id),
              'number': PlutoCell(value: e.number),
              'name': PlutoCell(value: e.name),
              'system': PlutoCell(value: e.system),
              'subsystem': PlutoCell(value: e.subsystem),
              'article': PlutoCell(value: e.article),
              'manufacturer': PlutoCell(value: e.manufacturer),
              'unit': PlutoCell(value: e.unit),
              'quantity': PlutoCell(value: e.quantity),
              'price': PlutoCell(value: e.price),
              'total': PlutoCell(value: e.total),
              'actions': PlutoCell(value: ''),
            }))
        .toList();
  }

  /// Показывает контекстное меню для действий над строкой
  void _showActionMenu(
      BuildContext context, Offset position, Estimate item, String itemId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
      items: [
        PopupMenuItem(
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Редактировать',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 10),
              () {
                if (!context.mounted) return;
                _showItemDialog(context, item);
              },
            );
          },
        ),
        PopupMenuItem(
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.copy_outlined,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Дублировать',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 10),
              () {
                if (!context.mounted) return;
                _duplicateItem(item);
              },
            );
          },
        ),
        PopupMenuItem(
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Удалить',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(
              const Duration(milliseconds: 10),
              () {
                if (!context.mounted) return;
                _delete(itemId);
              },
            );
          },
        ),
      ],
    );
  }

  /// Возвращает список уникальных систем из списка позиций
  List<String> _getUniqueSystems(List<Estimate> items) {
    final systems = <String>{};
    for (final item in items) {
      if (item.system.isNotEmpty) {
        systems.add(item.system);
      }
    }
    return systems.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimateNotifierProvider);
    final items = state.estimates
        .where((e) => e.estimateTitle == widget.estimateTitle)
        .toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final containerWidth =
        MediaQuery.of(context).size.width - 32; // 32 — padding
    const ruLocale = PlutoGridLocaleText(
      unfreezeColumn: 'Открепить',
      freezeColumnToStart: 'Закрепить в начале',
      freezeColumnToEnd: 'Закрепить в конце',
      autoFitColumn: 'Автоматический размер',
      hideColumn: 'Скрыть колонку',
      setColumns: 'Выбрать колонки',
      setFilter: 'Установить фильтр',
      resetFilter: 'Сбросить фильтр',
      setColumnsTitle: 'Column title',
      filterColumn: 'Колонка',
      filterType: 'Тип',
      filterValue: 'Значение',
      filterAllColumns: 'Все колонки',
      filterContains: 'Поиск',
      filterEquals: 'Равно',
      filterStartsWith: 'Начинается с',
      filterEndsWith: 'Заканчивается на',
      filterGreaterThan: 'Больше чем',
      filterGreaterThanOrEqualTo: 'Больше или равно',
      filterLessThan: 'Меньше чем',
      filterLessThanOrEqualTo: 'Меньше или равно',
      sunday: 'Вск',
      monday: 'Пн',
      tuesday: 'Вт',
      wednesday: 'Ср',
      thursday: 'Чт',
      friday: 'Пт',
      saturday: 'Сб',
      hour: 'Часы',
      minute: 'Минуты',
      loadingText: 'Загрузка',
    );

    // Строим таблицу только если экран достаточно широкий
    if (isLargeScreen) {
      _buildTable(items, containerWidth);
    }

    // Фильтруем и сортируем элементы для мобильного представления
    final filteredItems = isLargeScreen ? items : _filterAndSortItems(items);

    final cellStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final columnStyle =
        theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold);
    final moneyFormat = NumberFormat('###,##0.00', 'ru_RU');

    return Scaffold(
      appBar: AppBarWidget(
        title: widget.estimateTitle ?? 'Детали сметы',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => context.go('/estimates'),
        ),
        actions: [
          if (isLargeScreen)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Добавить позицию',
              onPressed: () => _showItemDialog(context),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Нет позиций для этой сметы'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить позицию'),
                        onPressed: () => _showItemDialog(context),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isLargeScreen
                      ? PlutoGrid(
                          columns: columns,
                          rows: rows,
                          mode: PlutoGridMode.normal,
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            stateManager = event.stateManager;
                            event.stateManager.setShowColumnFilter(true);
                          },
                          configuration: isDark
                              ? PlutoGridConfiguration.dark(
                                  localeText: ruLocale,
                                  style: PlutoGridStyleConfig.dark(
                                    columnFilterHeight: 36,
                                    cellTextStyle: cellStyle,
                                    columnTextStyle: columnStyle,
                                    gridBorderRadius: BorderRadius.circular(12),
                                    gridBorderColor: theme.colorScheme.outline
                                        .withValues(alpha: 0.12),
                                  ),
                                )
                              : PlutoGridConfiguration(
                                  localeText: ruLocale,
                                  style: PlutoGridStyleConfig(
                                    columnFilterHeight: 36,
                                    cellTextStyle: cellStyle,
                                    columnTextStyle: columnStyle,
                                    gridBorderRadius: BorderRadius.circular(12),
                                    gridBorderColor: theme.colorScheme.outline
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                        )
                      : // Мобильный вид вместо таблицы
                      Column(
                          children: [
                            // Верхний блок с поиском, статистикой и фильтрами в анимированном контейнере
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: _isHeaderVisible ? null : 0,
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isHeaderVisible ? 1.0 : 0.0,
                                child: Column(
                                  children: [
                                    // Поисковая строка и кнопка сортировки
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 30),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _searchController,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: 'Поиск по смете...',
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 8),
                                                  prefixIcon: Icon(Icons.search,
                                                      size: 20),
                                                ),
                                                onChanged: (_) =>
                                                    setState(() {}),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                size: 18,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Сортировка',
                                              onPressed: () =>
                                                  _showSortDialog(context),
                                            ),
                                            if (_searchController
                                                .text.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.clear,
                                                    size: 18),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                tooltip: 'Очистить',
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Статистика по смете
                                    Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 30),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Статистика по смете',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            // Основные параметры
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Позиций:',
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                  alpha: 0.7),
                                                        ),
                                                      ),
                                                      Text(
                                                        '${items.length}',
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Итого:',
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                  alpha: 0.7),
                                                        ),
                                                      ),
                                                      Text(
                                                        '${moneyFormat.format(items.fold(0.0, (sum, item) => sum + item.total))} ₽',
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Быстрые фильтры (системы)
                                    if (!isLargeScreen)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4, bottom: 4),
                                              child: Text(
                                                'Быстрые фильтры:',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children:
                                                    _getUniqueSystems(items)
                                                        .map((system) {
                                                  final isSelected =
                                                      _searchController.text
                                                              .toLowerCase() ==
                                                          system.toLowerCase();
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 6),
                                                    child: FilterChip(
                                                      label: Text(system,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                      selected: isSelected,
                                                      showCheckmark: false,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                      backgroundColor: theme
                                                          .colorScheme.surface,
                                                      selectedColor: theme
                                                          .colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.2),
                                                      side: BorderSide(
                                                        color: isSelected
                                                            ? theme.colorScheme
                                                                .primary
                                                            : theme.colorScheme
                                                                .outline
                                                                .withValues(
                                                                    alpha: 50),
                                                        width: 1,
                                                      ),
                                                      labelStyle: TextStyle(
                                                        color: isSelected
                                                            ? theme.colorScheme
                                                                .primary
                                                            : theme.colorScheme
                                                                .onSurface,
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : null,
                                                      ),
                                                      onSelected: (selected) {
                                                        setState(() {
                                                          if (selected &&
                                                              !isSelected) {
                                                            _searchController
                                                                .text = system;
                                                          } else {
                                                            _searchController
                                                                .clear();
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Счетчик найденных позиций и информация о сортировке
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Найдено: ${filteredItems.length} из ${items.length}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Сортировка: ',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              Text(
                                                {
                                                      'number': 'По номеру',
                                                      'name': 'По наименованию',
                                                      'system': 'По системе',
                                                      'price': 'По цене',
                                                      'total': 'По сумме',
                                                    }[_sortCriterion] ??
                                                    'По номеру',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Icon(
                                                _sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                size: 12,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Список позиций
                            Expanded(
                              child: filteredItems.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 48,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Нет результатов поиска',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Попробуйте изменить критерии поиска',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        // Дополнительная обработка событий прокрутки
                                        // Показываем верхний блок при прокрутке до начала списка
                                        if (notification
                                            is ScrollEndNotification) {
                                          if (_scrollController
                                                      .position.pixels ==
                                                  0 &&
                                              !_isHeaderVisible) {
                                            setState(() {
                                              _isHeaderVisible = true;
                                            });
                                          }
                                        }
                                        return false;
                                      },
                                      child: ListView.separated(
                                        controller: _scrollController,
                                        itemCount: filteredItems.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 4),
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) {
                                          final item = filteredItems[index];
                                          return EstimateItemCard(
                                            item: item,
                                            onEdit: (estimate) =>
                                                _showItemDialog(
                                                    context, estimate),
                                            onDuplicate: (estimate) =>
                                                _duplicateItem(estimate),
                                            onDelete: (id) => _delete(id),
                                          )
                                              .animate()
                                              .fadeIn(
                                                duration: 300.ms,
                                                delay: Duration(
                                                    milliseconds: 30 * index),
                                              )
                                              .slideX(begin: 0.05, end: 0);
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        ),
                ),
      floatingActionButton: !isLargeScreen
          ? FloatingActionButton(
              heroTag: 'addItem',
              tooltip: 'Добавить позицию',
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add),
              onPressed: () => _showItemDialog(context),
            )
          : null,
    );
  }
}

/// Стильная кнопка действий с анимацией при наведении курсора.
///
/// Используется для отображения кнопки действий в таблице позиций сметы.
/// При нажатии показывает контекстное меню с доступными действиями.
class ActionButton extends StatefulWidget {
  /// Обработчик нажатия на кнопку
  final void Function(TapDownDetails) onTap;

  /// Текущая тема приложения
  final ThemeData theme;

  /// Создает кнопку действий.
  ///
  /// Требует [onTap] обработчик для реагирования на нажатия и [theme] для
  /// стилизации кнопки в соответствии с текущей темой приложения.
  const ActionButton({
    super.key,
    required this.onTap,
    required this.theme,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.transparent,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Center(
            child: _isHovered
                ? const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.green,
                  )
                : const Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: Colors.red,
                  ),
          ),
        ),
      ),
    );
  }
}
