import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/presentation/state/contractor_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'contractor_form_screen.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/notifications_service.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';

/// Экран подробной информации о контрагенте (заказчик, подрядчик, поставщик).
///
/// Отображает карточку с основной информацией, табы с контактами и реквизитами, поддерживает редактирование и удаление.
/// Адаптируется под desktop и mobile, интегрирован с провайдером состояния [contractorProvider].
///
/// Пример использования:
/// ```dart
/// ContractorDetailsScreen(contractorId: 'id123');
/// ```
class ContractorDetailsScreen extends ConsumerStatefulWidget {
  /// Идентификатор контрагента для отображения.
  final String contractorId;
  /// Показывать ли AppBar и Drawer (по умолчанию true).
  final bool showAppBar;
  /// Создаёт экран деталей для контрагента с [contractorId].
  const ContractorDetailsScreen({super.key, required this.contractorId, this.showAppBar = true});

  @override
  ConsumerState<ContractorDetailsScreen> createState() => _ContractorDetailsScreenState();
}

/// Состояние для [ContractorDetailsScreen].
///
/// Управляет загрузкой, обновлением, табами и обработкой событий (редактирование, удаление).
class _ContractorDetailsScreenState extends ConsumerState<ContractorDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contractorProvider.notifier).getContractor(widget.contractorId);
    });
  }

  @override
  void didUpdateWidget(covariant ContractorDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contractorId != widget.contractorId) {
      Future.microtask(() {
        ref.read(contractorProvider.notifier).getContractor(widget.contractorId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Возвращает строковое представление типа контрагента.
  ///
  /// [type] — тип контрагента.
  String _typeLabel(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return 'Заказчик';
      case ContractorType.contractor:
        return 'Подрядчик';
      case ContractorType.supplier:
        return 'Поставщик';
    }
  }

  /// Возвращает цвет для типа контрагента.
  ///
  /// [type] — тип контрагента.
  Color _typeColor(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return Colors.blue;
      case ContractorType.contractor:
        return Colors.green;
      case ContractorType.supplier:
        return Colors.orange;
    }
  }

  /// Форматирует дату в строку "дд.мм.гггг" или "—" если null.
  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contractorProvider);
    final contractor = state.contractor;
    final isLoading = contractor == null && state.status == ContractorStatus.loading;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isLoading) {
      return Scaffold(
        appBar: widget.showAppBar ? const AppBarWidget(title: 'Информация о контрагенте') : null,
        drawer: widget.showAppBar ? const AppDrawer(activeRoute: AppRoute.contractors) : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.status == ContractorStatus.error || contractor == null) {
      return Scaffold(
        appBar: widget.showAppBar ? const AppBarWidget(title: 'Информация о контрагенте') : null,
        drawer: widget.showAppBar ? const AppDrawer(activeRoute: AppRoute.contractors) : null,
        body: Center(
          child: Text(
            state.errorMessage ?? 'Контрагент не найден',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    // --- HEADER ---
    Widget header = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Логотип
          Hero(
            tag: 'contractor_avatar_${contractor.id}',
            child: contractor.logoUrl != null && contractor.logoUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(contractor.logoUrl!),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.business, size: 40),
                  ),
          ),
          const SizedBox(width: 16),
          // Основная информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contractor.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  contractor.shortName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AppBadge(
                  text: _typeLabel(contractor.type),
                  color: _typeColor(contractor.type),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    const tabs = [
      Tab(text: 'Данные'),
      Tab(text: 'Контакты'),
      Tab(text: 'Реквизиты'),
    ];

    // --- MOBILE ---
    if (!isDesktop) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBarWidget(
                title: contractor.fullName,
                leading: const BackButton(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.amber),
                    tooltip: 'Редактировать',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                        ),
                        builder: (context) => Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
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
                                child: ContractorFormScreen(contractorId: contractor.id, showScaffold: false),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Удалить',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Удалить контрагента?'),
                          content: const Text('Вы уверены, что хотите удалить этого контрагента?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await ref.read(contractorProvider.notifier).deleteContractor(contractor.id);
                          if (context.mounted) {
                            context.goNamed('contractors');
                            NotificationsService.showErrorNotification(context, 'Контрагент удалён');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            NotificationsService.showErrorNotification(context, 'Ошибка удаления: ${e.toString()}');
                          }
                        }
                      }
                    },
                  ),
                ],
                showThemeSwitch: false,
              )
            : null,
        drawer: widget.showAppBar ? const AppDrawer(activeRoute: AppRoute.contractors) : null,
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            header,
            TabBar(
              controller: _tabController,
              tabs: tabs,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoSection('Основная информация', [
                        _buildInfoItem('Полное наименование', contractor.fullName),
                        _buildInfoItem('Сокращенное наименование', contractor.shortName),
                        _buildInfoItem('Тип', _typeLabel(contractor.type)),
                        _buildInfoItem('ИНН', contractor.inn),
                        _buildInfoItem('Директор', contractor.director),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection('Даты', [
                        _buildInfoItem('Создан', _formatDate(contractor.createdAt)),
                        _buildInfoItem('Обновлён', _formatDate(contractor.updatedAt)),
                      ]),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoSection('Контактная информация', [
                        _buildInfoItem('Телефон', contractor.phone),
                        _buildInfoItem('Почта', contractor.email),
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection('Адреса', [
                        _buildInfoItem('Юридический адрес', contractor.legalAddress),
                        _buildInfoItem('Фактический адрес', contractor.actualAddress),
                      ]),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoSection('Реквизиты', [
                        _buildInfoItem('ИНН', contractor.inn),
                        _buildInfoItem('Директор', contractor.director),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // --- DESKTOP ---
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          header,
          TabBar(
            controller: _tabController,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoSection('Основная информация', [
                      _buildInfoItem('Полное наименование', contractor.fullName),
                      _buildInfoItem('Сокращенное наименование', contractor.shortName),
                      _buildInfoItem('Тип', _typeLabel(contractor.type)),
                      _buildInfoItem('ИНН', contractor.inn),
                      _buildInfoItem('Директор', contractor.director),
                    ]),
                    const SizedBox(height: 16),
                    _buildInfoSection('Даты', [
                      _buildInfoItem('Создан', _formatDate(contractor.createdAt)),
                      _buildInfoItem('Обновлён', _formatDate(contractor.updatedAt)),
                    ]),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoSection('Контактная информация', [
                      _buildInfoItem('Телефон', contractor.phone),
                      _buildInfoItem('Почта', contractor.email),
                    ]),
                    const SizedBox(height: 16),
                    _buildInfoSection('Адреса', [
                      _buildInfoItem('Юридический адрес', contractor.legalAddress),
                      _buildInfoItem('Фактический адрес', contractor.actualAddress),
                    ]),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoSection('Реквизиты', [
                      _buildInfoItem('ИНН', contractor.inn),
                      _buildInfoItem('Директор', contractor.director),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
} 