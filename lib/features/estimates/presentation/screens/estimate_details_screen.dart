import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/object.dart';
import '../../../../domain/entities/contract.dart';
import '../../../../presentation/widgets/app_bar_widget.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../features/estimates/presentation/screens/import_estimate_form_modal.dart';
import '../../../../features/roles/application/permission_service.dart';
import '../../../../features/roles/presentation/widgets/permission_guard.dart';

import '../widgets/estimate_item_card.dart';
import '../widgets/estimate_edit_dialog.dart';
import '../widgets/estimate_table_view.dart';
import '../widgets/estimate_mobile_header.dart';

/// Экран для отображения детальной информации о смете.
///
/// Показывает таблицу позиций сметы с использованием PlutoGrid (на Desktop)
/// или список карточек с хедером (на Mobile).
class EstimateDetailsScreen extends ConsumerStatefulWidget {
  /// Название сметы для отображения.
  final String? estimateTitle;

  /// Флаг отображения AppBar.
  final bool showAppBar;

  /// Создаёт экран деталей сметы.
  const EstimateDetailsScreen({
    super.key,
    this.estimateTitle,
    this.showAppBar = true,
  });

  @override
  ConsumerState<EstimateDetailsScreen> createState() =>
      _EstimateDetailsScreenState();
}

/// Состояние для [EstimateDetailsScreen].
class _EstimateDetailsScreenState extends ConsumerState<EstimateDetailsScreen> {
  /// Контроллер для текста поиска
  final TextEditingController _searchController = TextEditingController();

  /// Критерий сортировки для мобильного вида
  String _sortCriterion = 'number';

  /// Порядок сортировки (по возрастанию/убыванию)
  bool _sortAscending = true;

  /// Генерация идентификаторов для новых строк
  final Uuid _uuid = const Uuid();

  /// Контроллер прокрутки для списка позиций
  final ScrollController _scrollController = ScrollController();

  /// Флаг видимости верхнего блока
  bool _isHeaderVisible = true;

  /// Предыдущая позиция прокрутки
  double _previousScrollPosition = 0;

  /// Минимальное смещение для срабатывания скрытия/показа
  final double _scrollThreshold = 20.0;

  /// Выбранная смета (для Desktop режима)
  EstimateFile? _selectedEstimateFile;

  @override
  void initState() {
    super.initState();
    // Добавляем слушатель прокрутки
    _scrollController.addListener(_scrollListener);
    // Слушаем изменения в поиске для обновления UI
    _searchController.addListener(_onSearchChanged);

    // Загружаем данные и инициализируем выбор
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(estimateNotifierProvider);
      // Если данные уже загружены или загружаются, просто инициализируем выбор.
      // Если список пуст и нет загрузки, пробуем загрузить.
      if (state.estimates.isNotEmpty) {
        _initSelection();
      } else if (!state.isLoading) {
        ref.read(estimateNotifierProvider.notifier).loadEstimates().then((_) {
          if (mounted) {
            _initSelection();
          }
        });
      }
    });
  }

  void _initSelection() {
    if (!mounted) return;
    if (widget.estimateTitle != null) {
      final state = ref.read(estimateNotifierProvider);
      final files = _groupEstimatesByFile(state.estimates);
      final found = files.firstWhereOrNull(
        (f) => f.estimateTitle == widget.estimateTitle,
      );
      if (found != null && mounted) {
        setState(() {
          _selectedEstimateFile = found;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  /// Слушатель прокрутки для управления видимостью верхнего блока
  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final currentPosition = _scrollController.position.pixels;
    final isScrollingDown = currentPosition > _previousScrollPosition;

    if ((currentPosition - _previousScrollPosition).abs() > _scrollThreshold) {
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
      _previousScrollPosition = currentPosition;
    }
  }

  /// Фильтрует и сортирует список позиций сметы
  List<Estimate> _filterAndSortItems(List<Estimate> items) {
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

    filteredItems.sort((a, b) {
      int result = 0;
      switch (_sortCriterion) {
        case 'number':
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
          result = a.number.compareTo(b.number);
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
              setState(() {
                _sortAscending = !_sortAscending;
              });
            } else {
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
                            ? CupertinoIcons.arrow_up
                            : CupertinoIcons.arrow_down)
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

  void _openEditDialog(BuildContext context, [Estimate? estimate]) {
    // Определяем название сметы: переданное в виджет или из выбранного файла
    final title = widget.estimateTitle ?? _selectedEstimateFile?.estimateTitle;

    // Определяем ID объекта и договора:
    // 1. Если редактирование - берем из estimate
    // 2. Если добавление - берем из выбранного файла
    final objectId = estimate?.objectId ?? _selectedEstimateFile?.objectId;
    final contractId =
        estimate?.contractId ?? _selectedEstimateFile?.contractId;

    EstimateEditDialog.show(
      context,
      estimate: estimate,
      estimateTitle: title,
      objectId: objectId,
      contractId: contractId,
    );
  }

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

  void _duplicateItem(Estimate estimate) {
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

  void _createDuplicate(Estimate estimate) {
    String newNumber = estimate.number;

    if (RegExp(r'^\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = int.parse(estimate.number);
        newNumber = (numValue + 1).toString();
      } catch (e) {
        newNumber = "${estimate.number}-копия";
      }
    } else if (RegExp(r'^\d+\.\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = double.parse(estimate.number);
        newNumber = (numValue + 0.1).toStringAsFixed(1);
      } catch (e) {
        newNumber = "${estimate.number}-копия";
      }
    } else if (RegExp(r'^\d+,\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = double.parse(estimate.number.replaceAll(',', '.'));
        newNumber = (numValue + 0.1).toStringAsFixed(1).replaceAll('.', ',');
      } catch (e) {
        newNumber = "${estimate.number}-копия";
      }
    } else if (RegExp(r'^([a-zA-Zа-яА-Я]+)-(\d+)$').hasMatch(estimate.number)) {
      final match =
          RegExp(r'^([a-zA-Zа-яА-Я]+)-(\d+)$').firstMatch(estimate.number);
      if (match != null) {
        final prefix = match.group(1);
        final numVal = int.parse(match.group(2)!);
        newNumber = "$prefix-${numVal + 1}";
      } else {
        newNumber = "${estimate.number}-копия";
      }
    } else {
      newNumber = "${estimate.number}-копия";
    }

    final newItem = estimate.copyWith(
      id: _uuid.v4(),
      number: newNumber,
    );
    ref.read(estimateNotifierProvider.notifier).addEstimate(newItem);
  }

  void _showImportEstimateBottomSheet(BuildContext context) {
    ImportEstimateFormModal.show(
      context,
      ref,
      onSuccess: () async {
        if (context.mounted) context.pop();
        SnackBarUtils.showSuccess(context, 'Смета успешно импортирована');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    // Для Desktop используем новый макет "как в профиле"
    if (isLargeScreen) {
      return _buildDesktopLayout(context);
    }

    // Для мобильных или встроенного режима (если showAppBar=false) оставляем старую логику
    final state = ref.watch(estimateNotifierProvider);

    // Если передан estimateTitle, используем его (старое поведение)
    // Если нет, пытаемся взять из выбранного файла
    final targetTitle =
        widget.estimateTitle ?? _selectedEstimateFile?.estimateTitle;

    final items =
        state.estimates.where((e) => e.estimateTitle == targetTitle).toList();

    final theme = Theme.of(context);

    final filteredItems = _filterAndSortItems(items);

    final body = state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(targetTitle == null
                        ? 'Выберите смету'
                        : 'Нет позиций для этой сметы'),
                    const SizedBox(height: 16),
                    if (targetTitle != null)
                      PermissionGuard(
                        module: 'estimates',
                        permission: 'create',
                        child: GTPrimaryButton(
                          icon: CupertinoIcons.add,
                          text: 'Добавить позицию',
                          onPressed: () => _openEditDialog(context),
                        ),
                      ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Анимированный хедер
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isHeaderVisible ? null : 0,
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isHeaderVisible ? 1.0 : 0.0,
                        child: EstimateMobileHeader(
                          searchController: _searchController,
                          items: items,
                          filteredCount: filteredItems.length,
                          sortCriterion: _sortCriterion,
                          sortAscending: _sortAscending,
                          onSortPressed: () => _showSortDialog(context),
                          onFilterSelected: (value) {
                            _searchController.text = value;
                          },
                        ),
                      ),
                    ),

                    // Список позиций
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.search,
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollEndNotification) {
                                  if (_scrollController.position.pixels == 0 &&
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
                                  final permissionService =
                                      ref.watch(permissionServiceProvider);
                                  return EstimateItemCard(
                                    item: item,
                                    canEdit: permissionService.can(
                                        'estimates', 'update'),
                                    canDelete: permissionService.can(
                                        'estimates', 'delete'),
                                    canDuplicate: permissionService.can(
                                        'estimates', 'create'),
                                    onEdit: (estimate) =>
                                        _openEditDialog(context, estimate),
                                    onDuplicate: (estimate) =>
                                        _duplicateItem(estimate),
                                    onDelete: (id) => _delete(id),
                                  )
                                      .animate()
                                      .fadeIn(
                                        duration: 300.ms,
                                        delay:
                                            Duration(milliseconds: 30 * index),
                                      )
                                      .slideX(begin: 0.05, end: 0);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              );

    if (!widget.showAppBar) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.isMobile(context) ? 16 : 0,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.estimateTitle != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.estimateTitle!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.estimateTitle != null) const Divider(height: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: widget.estimateTitle ?? 'Детали сметы',
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          tooltip: 'Назад',
          onPressed: () => context.go('/estimates'),
        ),
      ),
      body: body,
      floatingActionButton: PermissionGuard(
        module: 'estimates',
        permission: 'create',
        child: FloatingActionButton(
          heroTag: 'addItem',
          tooltip: 'Добавить позицию',
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _openEditDialog(context),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(estimateNotifierProvider);
    final estimateFiles = _groupEstimatesByFile(state.estimates);
    final contracts = ref.watch(contractProvider).contracts;
    final objects = ref.watch(objectProvider).objects;
    final permissionService = ref.watch(permissionServiceProvider);
    final canDelete = permissionService.can('estimates', 'delete');

    // Если выбранная смета исчезла (удалена), сбрасываем выбор
    if (_selectedEstimateFile != null &&
        !estimateFiles.any((f) =>
            f.estimateTitle == _selectedEstimateFile!.estimateTitle &&
            f.objectId == _selectedEstimateFile!.objectId &&
            f.contractId == _selectedEstimateFile!.contractId)) {
      // Используем микротаск, чтобы не вызвать setState во время build
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _selectedEstimateFile = null;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color.fromRGBO(38, 40, 42, 1)
                : const Color.fromRGBO(248, 249, 250, 1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Левая панель - список смет
                Container(
                  width: 350,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PermissionGuard(
                          module: 'estimates',
                          permission: 'import',
                          child: SizedBox(
                            width: double.infinity,
                            child: GTPrimaryButton(
                              text: 'Импорт сметы',
                              icon: CupertinoIcons.arrow_up_doc,
                              onPressed: () =>
                                  _showImportEstimateBottomSheet(context),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: state.isLoading && estimateFiles.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : estimateFiles.isEmpty
                                ? const Center(child: Text('Сметы не найдены'))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListView.separated(
                                      itemCount: estimateFiles.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                      itemBuilder: (context, index) {
                                        final file = estimateFiles[index];
                                        final isSelected = _selectedEstimateFile
                                                    ?.estimateTitle ==
                                                file.estimateTitle &&
                                            _selectedEstimateFile?.objectId ==
                                                file.objectId &&
                                            _selectedEstimateFile?.contractId ==
                                                file.contractId;

                                        return _EstimateListTile(
                                          file: file,
                                          contracts: contracts,
                                          objects: objects,
                                          isSelected: isSelected,
                                          canDelete: canDelete,
                                          onTap: () {
                                            setState(() {
                                              _selectedEstimateFile = file;
                                            });
                                          },
                                          onDelete: () =>
                                              _deleteEstimateFile(file),
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),

                // Правая панель - детали
                Expanded(
                  child: _selectedEstimateFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.list_bullet,
                                size: 64,
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Выберите смету из списка',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Хедер выбранной сметы
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedEstimateFile!.estimateTitle,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (MediaQuery.of(context).size.width > 900)
                                      PermissionGuard(
                                        module: 'estimates',
                                        permission: 'create',
                                        child: GTPrimaryButton(
                                          icon: CupertinoIcons.add,
                                          text: 'Добавить позицию',
                                          onPressed: () =>
                                              _openEditDialog(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              // Таблица
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: EstimateTableView(
                                    items: state.estimates
                                        .where((e) =>
                                            e.estimateTitle ==
                                            _selectedEstimateFile!
                                                .estimateTitle)
                                        .toList(),
                                    onEdit: (estimate) =>
                                        _openEditDialog(context, estimate),
                                    onDuplicate: _duplicateItem,
                                    onDelete: _delete,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteEstimateFile(EstimateFile file) async {
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удаление сметы',
      message:
          'Вы действительно хотите удалить смету "${file.estimateTitle}" и все её позиции?',
      onConfirm: () {},
    );

    if (confirmed == true) {
      final notifier = ref.read(estimateNotifierProvider.notifier);
      for (final item in file.items) {
        await notifier.deleteEstimate(item.id);
      }
      await notifier.loadEstimates();

      if (_selectedEstimateFile?.estimateTitle == file.estimateTitle) {
        setState(() {
          _selectedEstimateFile = null;
        });
      }
    }
  }
}

/// Класс, представляющий сгруппированный файл сметы.
///
/// Содержит информацию о названии сметы, привязанном объекте, договоре
/// и списке позиций, входящих в эту смету.
class EstimateFile {
  /// Название сметы.
  final String estimateTitle;

  /// Идентификатор объекта, к которому относится смета.
  final String? objectId;

  /// Идентификатор договора, к которому относится смета.
  final String? contractId;

  /// Список позиций сметы.
  final List<Estimate> items;

  /// Создаёт экземпляр файла сметы.
  const EstimateFile({
    required this.estimateTitle,
    required this.objectId,
    required this.contractId,
    required this.items,
  });

  /// Общая сумма по всем позициям сметы.
  double get total => items.fold(0, (sum, e) => sum + e.total);
}

List<EstimateFile> _groupEstimatesByFile(List<Estimate> estimates) {
  final grouped = groupBy(
    estimates,
    (Estimate e) => '${e.estimateTitle}_${e.objectId}_${e.contractId}',
  );
  return grouped.entries.map((entry) {
    final first = entry.value.first;
    return EstimateFile(
      estimateTitle: first.estimateTitle ?? 'Без названия',
      objectId: first.objectId,
      contractId: first.contractId,
      items: entry.value,
    );
  }).toList();
}

class _EstimateListTile extends StatelessWidget {
  final EstimateFile file;
  final List<Contract> contracts;
  final List<ObjectEntity> objects;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EstimateListTile({
    required this.file,
    required this.contracts,
    required this.objects,
    required this.isSelected,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contract = contracts.firstWhereOrNull((c) => c.id == file.contractId);
    final object = objects.firstWhereOrNull((o) => o.id == file.objectId);
    final contractNumber = contract?.number ?? '—';
    final objectName = object?.name ?? '—';

    return Material(
      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      file.estimateTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? theme.colorScheme.onPrimary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.trash,
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.error,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Договор: $contractNumber',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                'Объект: $objectName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(file.total),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
