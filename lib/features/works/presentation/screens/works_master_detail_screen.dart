import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/work_provider.dart';
import 'work_details_panel.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/work_hour.dart';
import '../providers/work_hours_provider.dart';
import '../providers/work_items_provider.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'dart:developer' as developer;
import 'package:flutter_svg/flutter_svg.dart';

/// Экран списка смен с поддержкой поиска, фильтрации и адаптивного отображения.
///
/// - На десктопе реализован мастер-детейл паттерн (список + детали).
/// - На мобильных поиск открывается жестом вниз, поддерживается pull-to-refresh.
/// - Использует Riverpod для управления состоянием и загрузкой данных.
class WorksMasterDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка смен.
  const WorksMasterDetailScreen({super.key});

  @override
  ConsumerState<WorksMasterDetailScreen> createState() => _WorksMasterDetailScreenState();
}

class _WorksMasterDetailScreenState extends ConsumerState<WorksMasterDetailScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchVisible = false;
  Work? selectedWork;
  
  /// Кэш профилей пользователей для оптимизации отображения.
  final Map<String, Profile?> _profileCache = {};
  
  /// Получает профиль пользователя из кэша или репозитория.
  Future<Profile?> _getUserProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }
    
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile(userId);
      _profileCache[userId] = profile;
      return profile;
    } catch (e) {
      developer.log('Error fetching profile for user $userId: $e', name: 'works_master_detail_screen');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_isMobileDevice() && _scrollController.position.pixels < -50) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
      }
    } else if (_scrollController.position.pixels > 0 && _isSearchVisible && _isMobileDevice()) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  /// Проверяет, является ли устройство мобильным (ширина экрана < 600).
  bool _isMobileDevice() {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  /// Фильтрует список смен по строке поиска [query].
  void _filterWorks(String query) {
    setState(() {});
  }

  /// Обрабатывает pull-to-refresh.
  Future<void> _handleRefresh() async {
    if (!_isSearchVisible) {
      setState(() {
        _isSearchVisible = true;
      });
      return Future.delayed(const Duration(milliseconds: 500));
    }
    await ref.read(worksProvider.notifier).loadWorks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worksState = ref.watch(worksProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final works = worksState.works;
    final isLoading = worksState.isLoading;
    final searchQuery = _searchController.text;
    
    // Фильтруем и сортируем смены
    final filteredWorks = List<Work>.from(
      searchQuery.isEmpty
        ? works
        : works.where((w) {
            final objectName = ref.watch(objectProvider).objects
                .where((o) => o.id == w.objectId)
                .map((o) => o.name)
                .firstOrNull ?? '';
                
            return w.objectId.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  w.status.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  objectName.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList()
    )..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(
        title: 'Смены',
        showThemeSwitch: true,
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.works),
      floatingActionButton: !isDesktop ? FloatingActionButton(
        heroTag: "mobile_add_shift",
        onPressed: () {
          final theme = Theme.of(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
            ),
            builder: (context) {
              final isDesktop = ResponsiveUtils.isDesktop(context);
              Widget modalContent = Container(
                margin: isDesktop ? const EdgeInsets.only(top: 48) : null,
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
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: const OpenShiftFormModal(),
                    ),
                  ),
                ),
              );
              if (isDesktop) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.isDesktop(context) 
                        ? MediaQuery.of(context).size.width * 0.5 
                        : MediaQuery.of(context).size.width,
                    ),
                    child: modalContent,
                  ),
                );
              } else {
                return modalContent;
              }
            },
          );
        },
        tooltip: 'Добавить смену',
        child: const Icon(Icons.add),
      ) : null,
      body: LayoutBuilder(
        builder: (scaffoldContext, constraints) {
          if (isDesktop) {
            return Row(
              children: [
                // Список смен (мастер)
                SizedBox(
                  width: 570,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Поле поиска
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Поиск смен',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterWorks('');
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: _filterWorks,
                            ),
                          ),
                          // Список смен
                          Expanded(
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : filteredWorks.isEmpty
                                    ? const Center(child: Text('Смены не найдены'))
                                    : RefreshIndicator(
                                        onRefresh: _handleRefresh,
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          itemCount: filteredWorks.length,
                                          itemBuilder: (context, i) {
                                            final work = filteredWorks[i];
                                            final selected = work.id == selectedWork?.id;
                                            
                                            // Получаем название объекта
                                            final objectName = ref.watch(objectProvider).objects
                                                .where((o) => o.id == work.objectId)
                                                .map((o) => o.name)
                                                .firstOrNull ?? work.objectId;
                                                
                                            // Получаем статус работы с цветом
                                            final (statusText, statusColor) = _getWorkStatusInfo(work.status);
                                            
                                            return FutureBuilder<Profile?>(
                                              future: _getUserProfile(work.openedBy),
                                              builder: (context, snapshot) {
                                                final String createdBy = snapshot.hasData && snapshot.data?.shortName != null
                                                    ? snapshot.data!.shortName!
                                                    : 'ID: ${work.openedBy.length > 4 ? "${work.openedBy.substring(0, 4)}..." : work.openedBy}';
                                                
                                                return Card(
                                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    side: BorderSide(
                                                      color: selected
                                                          ? Colors.green
                                                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                                                      width: selected ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedWork = work;
                                                      });
                                                    },
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Stack(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.all(12.0),
                                                          child: Row(
                                                            children: [
                                                              // Иконка смены вместо фото
                                                              Container(
                                                                width: 48,
                                                                height: 48,
                                                                decoration: BoxDecoration(
                                                                  color: theme.colorScheme.surface,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(
                                                                    color: theme.colorScheme.outlineVariant,
                                                                  ),
                                                                ),
                                                                child: SvgPicture.asset(
                                                                  work.status.toLowerCase() == 'closed'
                                                                      ? 'assets/icons/lock.svg'
                                                                      : 'assets/icons/lock_open.svg',
                                                                  colorFilter: ColorFilter.mode(
                                                                    work.status.toLowerCase() == 'closed' ? Colors.red : Colors.green,
                                                                    BlendMode.srcIn,
                                                                  ),
                                                                  width: 32,
                                                                  height: 32,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              // Информация о смене
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      _formatDate(work.date),
                                                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                                                    ),
                                                                    const SizedBox(height: 4),
                                                                    Text(
                                                                      objectName,
                                                                      style: theme.textTheme.bodySmall,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                    const SizedBox(height: 2),
                                                                    Text(
                                                                      'Открыл: $createdBy',
                                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                                        color: theme.colorScheme.secondary,
                                                                        fontSize: 12,
                                                                      ),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 8,
                                                          right: 8,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              AppBadge(
                                                            text: statusText,
                                                            color: statusColor,
                                                              ),
                                                              const SizedBox(height: 8),
                                                              // Общая сумма и выработка
                                                              Consumer(
                                                                builder: (context, ref, _) {
                                                                  if (work.id == null) return const SizedBox.shrink();
                                                                  
                                                                  final itemsAsync = ref.watch(workItemsProvider(work.id!));
                                                                  final hoursAsync = ref.watch(workHoursProvider(work.id!));
                                                                  
                                                                  return itemsAsync.when(
                                                                    data: (items) => hoursAsync.when(
                                                                      data: (hours) {
                                                                        // Расчет общей суммы
                                                                        final totalAmount = items.fold<double>(
                                                                          0, 
                                                                          (sum, item) => sum + (item.total ?? 0)
                                                                        );
                                                                        
                                                                        // Количество уникальных сотрудников
                                                                        final uniqueEmployees = hours.map((h) => h.employeeId).toSet().length;
                                                                        
                                                                        // Выработка на сотрудника
                                                                        final productivityPerEmployee = uniqueEmployees > 0 
                                                                          ? totalAmount / uniqueEmployees 
                                                                          : 0.0;
                                                                        
                                                                        final formatter = NumberFormat('#,##0', 'ru_RU');
                                                                        
                                                                        return Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                                          children: [
                                                                            Text(
                                                                              '${formatter.format(totalAmount)} ₽',
                                                                              style: theme.textTheme.bodySmall?.copyWith(
                                                                                fontWeight: FontWeight.w600,
                                                                                color: theme.colorScheme.primary,
                                                                              ),
                                                                            ),
                                                                            if (uniqueEmployees > 0) ...[
                                                                              const SizedBox(height: 2),
                                                                              Text(
                                                                                '${formatter.format(productivityPerEmployee)} ₽/чел',
                                                                                style: theme.textTheme.bodySmall?.copyWith(
                                                                                  fontSize: 10,
                                                                                  color: theme.colorScheme.secondary,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ],
                                                                        );
                                                                      },
                                                                      loading: () => const SizedBox.shrink(),
                                                                      error: (_, __) => const SizedBox.shrink(),
                                                                    ),
                                                                    loading: () => const SizedBox.shrink(),
                                                                    error: (_, __) => const SizedBox.shrink(),
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                            );
                                          },
                                        ),
                                      ),
                          ),
                        ],
                      ),
                      // FAB только для десктопа
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: FloatingActionButton(
                          heroTag: "desktop_add_shift",
                          onPressed: () {
                            final theme = Theme.of(context);
                            showModalBottomSheet(
                              context: scaffoldContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                              ),
                              builder: (context) {
                                final isDesktop = ResponsiveUtils.isDesktop(context);
                                Widget modalContent = Container(
                                  margin: isDesktop ? const EdgeInsets.only(top: 48) : null,
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
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).viewInsets.bottom,
                                        ),
                                        child: const OpenShiftFormModal(),
                                      ),
                                    ),
                                  ),
                                );
                                if (isDesktop) {
                                  return Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: ResponsiveUtils.isDesktop(context) 
                                          ? MediaQuery.of(context).size.width * 0.5 
                                          : MediaQuery.of(context).size.width,
                                      ),
                                      child: modalContent,
                                    ),
                                  );
                                } else {
                                  return modalContent;
                                }
                              },
                            );
                          },
                          tooltip: 'Добавить смену',
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                ),
                // Детали смены (детейл)
                Expanded(
                  child: selectedWork == null
                      ? Center(
                          child: Text(
                            'Выберите смену из списка',
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : selectedWork!.id != null
                          ? WorkDetailsPanel(workId: selectedWork!.id!, parentContext: scaffoldContext)
                          : const Center(child: Text('Ошибка: ID смены не задан')),
                ),
              ],
            );
          } else {
            // Мобильный режим
            return Column(
              children: [
                // Поле поиска (скрываемое)
                if (_isSearchVisible)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Поиск смен',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterWorks('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _filterWorks,
                    ),
                  ),
                // Список смен
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredWorks.isEmpty
                          ? const Center(child: Text('Смены не найдены'))
                          : RefreshIndicator(
                              onRefresh: _handleRefresh,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: filteredWorks.length,
                                itemBuilder: (context, i) {
                                  final work = filteredWorks[i];
                                  
                                  // Получаем название объекта
                                  final objectName = ref.watch(objectProvider).objects
                                      .where((o) => o.id == work.objectId)
                                      .map((o) => o.name)
                                      .firstOrNull ?? work.objectId;
                                      
                                  // Получаем статус работы с цветом
                                  final (statusText, statusColor) = _getWorkStatusInfo(work.status);
                                  
                                  return FutureBuilder<Profile?>(
                                    future: _getUserProfile(work.openedBy),
                                    builder: (context, snapshot) {
                                      final String createdBy = snapshot.hasData && snapshot.data?.shortName != null
                                          ? snapshot.data!.shortName!
                                          : 'ID: ${work.openedBy.length > 4 ? "${work.openedBy.substring(0, 4)}..." : work.openedBy}';
                                          
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            if (work.id != null) {
                                              context.goNamed(
                                                'work_details',
                                                pathParameters: {'workId': work.id!},
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Stack(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Row(
                                                  children: [
                                                    // Иконка смены вместо фото
                                                    Container(
                                                      width: 48,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.surface,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: theme.colorScheme.outlineVariant,
                                                        ),
                                                      ),
                                                      child: SvgPicture.asset(
                                                        work.status.toLowerCase() == 'closed'
                                                            ? 'assets/icons/lock.svg'
                                                            : 'assets/icons/lock_open.svg',
                                                        colorFilter: ColorFilter.mode(
                                                          work.status.toLowerCase() == 'closed' ? Colors.red : Colors.green,
                                                          BlendMode.srcIn,
                                                        ),
                                                        width: 32,
                                                        height: 32,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Информация о смене
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            _formatDate(work.date),
                                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            objectName,
                                                            style: theme.textTheme.bodySmall,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Открыл: $createdBy',
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: theme.colorScheme.secondary,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    AppBadge(
                                                  text: statusText,
                                                  color: statusColor,
                                                ),
                                                    const SizedBox(height: 8),
                                                    // Общая сумма и выработка
                                                    Consumer(
                                                      builder: (context, ref, _) {
                                                        if (work.id == null) return const SizedBox.shrink();
                                                        
                                                        final itemsAsync = ref.watch(workItemsProvider(work.id!));
                                                        final hoursAsync = ref.watch(workHoursProvider(work.id!));
                                                        
                                                        return itemsAsync.when(
                                                          data: (items) => hoursAsync.when(
                                                            data: (hours) {
                                                              // Расчет общей суммы
                                                              final totalAmount = items.fold<double>(
                                                                0, 
                                                                (sum, item) => sum + (item.total ?? 0)
                                                              );
                                                              
                                                              // Количество уникальных сотрудников
                                                              final uniqueEmployees = hours.map((h) => h.employeeId).toSet().length;
                                                              
                                                              // Выработка на сотрудника
                                                              final productivityPerEmployee = uniqueEmployees > 0 
                                                                ? totalAmount / uniqueEmployees 
                                                                : 0.0;
                                                              
                                                              final formatter = NumberFormat('#,##0', 'ru_RU');
                                                              
                                                                                                                             return Column(
                                                                 crossAxisAlignment: CrossAxisAlignment.end,
                                                                 children: [
                                                                   Text(
                                                                     '${formatter.format(totalAmount)} ₽',
                                                                     style: theme.textTheme.bodySmall?.copyWith(
                                                                       fontWeight: FontWeight.w600,
                                                                       color: theme.colorScheme.primary,
                                                                     ),
                                                                   ),
                                                                   if (uniqueEmployees > 0) ...[
                                                                     const SizedBox(height: 2),
                                                                     Text(
                                                                       '${formatter.format(productivityPerEmployee)} ₽/чел',
                                                                       style: theme.textTheme.bodySmall?.copyWith(
                                                                         fontSize: 10,
                                                                         color: theme.colorScheme.secondary,
                                                                       ),
                                                                     ),
                                                                   ],
                                                                 ],
                                                               );
                                                            },
                                                            loading: () => const SizedBox.shrink(),
                                                            error: (_, __) => const SizedBox.shrink(),
                                                          ),
                                                          loading: () => const SizedBox.shrink(),
                                                          error: (_, __) => const SizedBox.shrink(),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  );
                                },
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Форматирует дату в строку ДД.ММ.ГГГГ.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Возвращает текст и цвет статуса смены.
  (String, Color) _getWorkStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', Colors.green);
      case 'closed':
        return ('Закрыта', Colors.red);
      default:
        return (status, Colors.blue);
    }
  }
}

/// Модальное окно для открытия новой смены.
class OpenShiftFormModal extends ConsumerStatefulWidget {
  /// Создаёт модальное окно для открытия смены.
  const OpenShiftFormModal({super.key});

  @override
  ConsumerState<OpenShiftFormModal> createState() => _OpenShiftFormModalState();
}

class _OpenShiftFormModalState extends ConsumerState<OpenShiftFormModal> {
  String? _selectedObjectId;
  final List<String> _selectedEmployeeIds = [];
  String? _photoUrl;
  final TextEditingController _objectController = TextEditingController();
  
  // Кеширование для предотвращения мерцания
  Set<String>? _cachedOccupiedEmployeeIds;
  bool _isLoadingOccupiedEmployees = false;

  @override
  void initState() {
    super.initState();
    // Предзагружаем список занятых сотрудников
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOccupiedEmployees();
    });
  }

  /// Обновляет список занятых сотрудников с кешированием
  Future<void> _updateOccupiedEmployees() async {
    if (_isLoadingOccupiedEmployees) return;
    
    setState(() {
      _isLoadingOccupiedEmployees = true;
    });
    
    try {
      final occupiedIds = await _getEmployeesInOpenShifts();
      if (mounted) {
        setState(() {
          _cachedOccupiedEmployeeIds = occupiedIds;
          _isLoadingOccupiedEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedOccupiedEmployeeIds = <String>{};
          _isLoadingOccupiedEmployees = false;
        });
      }
    }
  }

  /// Получает список ID сотрудников, которые уже заняты в открытых сменах на текущую дату
  Future<Set<String>> _getEmployeesInOpenShifts() async {
    final worksState = ref.read(worksProvider);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // Получаем все открытые смены на сегодня
    final openWorksToday = worksState.works.where((work) {
      final workDate = DateTime(work.date.year, work.date.month, work.date.day);
      return work.status.toLowerCase() == 'open' && 
             workDate.isAtSameMomentAs(todayStart);
    }).toList();
    
    final occupiedEmployeeIds = <String>{};
    
    // Для каждой открытой смены получаем список сотрудников
    for (final work in openWorksToday) {
      if (work.id != null) {
        try {
          final workHoursAsync = ref.read(workHoursProvider(work.id!));
          final workHours = workHoursAsync.valueOrNull ?? [];
          for (final hour in workHours) {
            occupiedEmployeeIds.add(hour.employeeId);
          }
        } catch (e) {
          // Игнорируем ошибки загрузки для отдельных смен
          continue;
        }
      }
    }
    
    return occupiedEmployeeIds;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photoService = ref.read(photoServiceProvider);
    final file = await photoService.pickImage(source);
    if (file == null) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.contain, height: 240),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final url = await photoService.uploadPhoto(
      entity: 'shift',
      id: '', // Можно подставить id смены, если есть
      file: file,
      displayName: 'Смена',
    );
    if (!mounted) return;
    if (url != null) {
      setState(() {
        _photoUrl = url;
      });
    }
  }

  void _showPhotoOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Фото смены',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoOptionButton(
                  icon: Icons.photo_camera,
                  label: 'Камера',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                _PhotoOptionButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                if (_photoUrl != null && _photoUrl!.isNotEmpty)
                  _PhotoOptionButton(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() {
                        _photoUrl = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).profile;
    final allObjects = ref.watch(objectRepositoryProvider).getObjects();
    final allEmployees = ref.watch(employeeRepositoryProvider).getEmployees();
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return FutureBuilder(
      future: Future.wait([allObjects, allEmployees]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final objects = (snapshot.data![0] as List<ObjectEntity>);
        final employees = (snapshot.data![1] as List<Employee>);
        final profileObjectIds = profile?.objectIds ?? [];
        final availableObjects = objects.where((o) => profileObjectIds.contains(o.id)).toList();
        
        // Базовая фильтрация сотрудников по объекту и статусу
        final baseFilteredEmployees = _selectedObjectId == null
            ? <Employee>[]
            : employees
                .where((e) => e.objectIds.contains(_selectedObjectId))
                .where((e) => e.status == EmployeeStatus.working)
                .toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Открытие смены',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Информация о смене', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: dateStr,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Дата',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TypeAheadField<ObjectEntity>(
                            controller: _objectController,
                            suggestionsCallback: (pattern) {
                              return availableObjects
                                  .where((obj) => obj.name.toLowerCase().contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion.name),
                              );
                            },
                            onSelected: (suggestion) {
                              setState(() {
                                _selectedObjectId = suggestion.id;
                                _objectController.text = suggestion.name;
                                _selectedEmployeeIds.clear();
                              });
                                    // Обновляем список занятых сотрудников при смене объекта
                                    _updateOccupiedEmployees();
                            },
                            builder: (context, controller, focusNode) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Объект',
                                  prefixIcon: const Icon(Icons.location_city),
                                  suffixIcon: controller.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          tooltip: 'Очистить',
                                          onPressed: () {
                                            setState(() {
                                              _selectedObjectId = null;
                                              _objectController.clear();
                                              _selectedEmployeeIds.clear();
                                                    _cachedOccupiedEmployeeIds = null;
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                readOnly: false,
                              );
                            },
                            emptyBuilder: (context) => const ListTile(
                              title: Text('Нет совпадений'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Сотрудники', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Отображаются только сотрудники со статусом "Работает"',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                                // Оптимизированная фильтрация сотрудников с кешированием
                                _buildEmployeesList(baseFilteredEmployees, theme),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _showPhotoOptions,
                                child: Container(
                                  height: 170,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.colorScheme.surface,
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_photoUrl != null && _photoUrl!.isNotEmpty)
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(_photoUrl!, fit: BoxFit.cover),
                                          ),
                                        )
                                      else
                                        Center(
                                          child: Icon(Icons.photo, size: 48, color: theme.hintColor),
                                        ),
                                      if (_photoUrl != null && _photoUrl!.isNotEmpty)
                                        Positioned(
                                          top: 8, right: 8,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            tooltip: 'Удалить фото',
                                            onPressed: () {
                                              setState(() {
                                                _photoUrl = null;
                                              });
                                            },
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 8, right: 8,
                                        child: IconButton(
                                          icon: Icon(Icons.edit, color: theme.primaryColor),
                                          tooltip: _photoUrl != null && _photoUrl!.isNotEmpty ? 'Заменить фото' : 'Добавить фото',
                                          onPressed: _showPhotoOptions,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Фото смены (необязательно)', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedObjectId != null && _selectedEmployeeIds.isNotEmpty
                              ? () async {
                                  final notifier = ref.read(worksProvider.notifier);
                                  final profile = ref.read(profileProvider).profile;
                                  if (profile == null) return;
                                  
                                  // Создаем смену и получаем её модель
                                  final createdWork = await notifier.addWork(
                                    date: DateTime.now(),
                                    objectId: _selectedObjectId!,
                                    openedBy: profile.id,
                                    status: 'open',
                                    photoUrl: _photoUrl,
                                  );
                                  
                                  if (createdWork != null && createdWork.id != null) {
                                    // Добавляем сотрудников в таблицу work_hours
                                    final hoursNotifier = ref.read(workHoursProvider(createdWork.id!).notifier);
                                    
                                    // Для каждого выбранного сотрудника создаем запись с 0 часов
                                    for (final employeeId in _selectedEmployeeIds) {
                                      final workHour = WorkHour(
                                        id: const Uuid().v4(),
                                        workId: createdWork.id!,
                                        employeeId: employeeId,
                                        hours: 0, // По умолчанию 0 часов
                                        comment: null,
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      );
                                      await hoursNotifier.add(workHour);
                                    }
                                  }
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                          SnackBarUtils.showSuccess(context, 'Смена успешно открыта');
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Открыть смену'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
      );
  }

  /// Строит список сотрудников с оптимизированной фильтрацией
  Widget _buildEmployeesList(List<Employee> baseFilteredEmployees, ThemeData theme) {
    if (_selectedObjectId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Выберите объект для отображения сотрудников',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Используем кешированные данные если они есть и актуальны
    if (_isLoadingOccupiedEmployees) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final occupiedEmployeeIds = _cachedOccupiedEmployeeIds ?? <String>{};
    
    // Финальная фильтрация: исключаем занятых сотрудников
    final availableEmployees = baseFilteredEmployees
        .where((e) => !occupiedEmployeeIds.contains(e.id))
        .toList();
    
    if (availableEmployees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Нет доступных сотрудников для выбранного объекта',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Column(
      children: availableEmployees.map((emp) {
        final isSelected = _selectedEmployeeIds.contains(emp.id);
        return CheckboxListTile(
          value: isSelected,
          title: Text('${emp.lastName} ${emp.firstName}${emp.middleName != null && emp.middleName!.isNotEmpty ? ' ${emp.middleName}' : ''}'),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _selectedEmployeeIds.add(emp.id);
              } else {
                _selectedEmployeeIds.remove(emp.id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}

class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoOptionButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
} 