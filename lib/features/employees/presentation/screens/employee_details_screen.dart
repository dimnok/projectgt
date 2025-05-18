import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/notifications_service.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Экран с подробной информацией о сотруднике.
///
/// Отображает данные сотрудника, связанные объекты, статус, а также позволяет редактировать и удалять сотрудника.
class EmployeeDetailsScreen extends ConsumerStatefulWidget {
  /// ID сотрудника для отображения.
  final String employeeId;
  /// Показывать ли AppBar и Drawer.
  final bool showAppBar;

  /// Создаёт экран деталей сотрудника.
  const EmployeeDetailsScreen({
    super.key,
    required this.employeeId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends ConsumerState<EmployeeDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Константные значения для повторяющихся отступов
  static const double _contentPadding = 16.0;
  static const double _sectionSpacing = 16.0;
  static const double _labelWidth = 150.0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Загружаем данные сотрудника
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(state.employeeProvider.notifier).getEmployee(widget.employeeId);
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Форматирование даты
  String _formatDate(DateTime? date) {
    if (date == null) return 'Не указана';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(state.employeeProvider);
    final employee = employeeState.employee;
    final isLoading = employee == null && employeeState.status == state.EmployeeStatus.loading;
    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;
    
    if (isLoading) {
      return Scaffold(
        appBar: widget.showAppBar ? const AppBarWidget(title: 'Информация о сотруднике') : null,
        drawer: widget.showAppBar ? const AppDrawer(activeRoute: AppRoute.employees) : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (employee == null) {
      return Scaffold(
        appBar: widget.showAppBar ? const AppBarWidget(title: 'Информация о сотруднике') : null,
        drawer: widget.showAppBar ? const AppDrawer(activeRoute: AppRoute.employees) : null,
        body: Center(
          child: Text(
            'Сотрудник не найден',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    
    // Получаем данные для отображения только один раз
    final (statusText, statusColor) = EmployeeUIUtils.getStatusInfo(employee.status);
    final employmentTypeText = EmployeeUIUtils.getEmploymentTypeText(employee.employmentType);
    // Получаем имена объектов по objectIds
    String objectsText = 'Не указаны';
    if (employee.objectIds.isNotEmpty) {
      final names = employee.objectIds.map((id) => objects.firstWhere(
        (o) => o.id == id,
        orElse: () => const ObjectEntity(id: '', name: '—', address: ''),
      ).name).where((name) => name != '—').toList();
      if (names.isNotEmpty) {
        objectsText = names.join(', ');
      }
    }
    
    // Адаптивные значения в зависимости от размера экрана
    final double avatarRadius = ResponsiveUtils.adaptiveValue(
      context: context,
      mobile: 40.0,
      desktop: 50.0,
    );
    
    // Предварительно создаем общую тень для переиспользования
    final commonBoxShadow = BoxShadow(
      color: theme.colorScheme.shadow.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    );
    
    // Общий стиль для заголовков секций
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    
    // Общий стиль для меток
    final labelStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: ResponsiveUtils.adaptiveValue(
        context: context, 
        mobile: 14.0,
        desktop: 15.0
      ),
    );
    
    // Общий стиль для значений
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: ResponsiveUtils.adaptiveValue(
        context: context, 
        mobile: 15.0,
        desktop: 16.0
      ),
    );
    
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBarWidget(
              title: '${employee.lastName} ${employee.firstName}',
              leading: const BackButton(),
              showThemeSwitch: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.amber),
                  tooltip: 'Редактировать',
                  onPressed: () {
                    ModalUtils.showEmployeeFormModal(context, employeeId: employee.id);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Удалить',
                  onPressed: () => _showDeleteDialog(employee),
                ),
              ],
            )
          : null,
      drawer: null,
      body: Column(
        children: [
          // Шапка с фото и основной информацией
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.adaptiveValue(
              context: context,
              mobile: _contentPadding,
              desktop: _contentPadding * 1.5,
            )),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [commonBoxShadow],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Фото сотрудника
                Hero(
                  tag: 'employee_avatar_${employee.id}',
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: theme.colorScheme.surface,
                      child: employee.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: employee.photoUrl!,
                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                radius: avatarRadius,
                                backgroundImage: imageProvider,
                              ),
                              placeholder: (context, url) => SizedBox(
                                width: avatarRadius / 2,
                                height: avatarRadius / 2,
                                child: const CircularProgressIndicator.adaptive(),
                              ),
                              errorWidget: (context, url, error) => CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
                                  size: avatarRadius,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: avatarRadius,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Основная информация о сотруднике
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ФИО
                      Text(
                        '${employee.lastName} ${employee.firstName}${employee.middleName != null ? ' ${employee.middleName}' : ''}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.adaptiveValue(
                            context: context,
                            mobile: theme.textTheme.titleLarge?.fontSize ?? 22.0,
                            desktop: (theme.textTheme.titleLarge?.fontSize ?? 22.0) * 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.adaptiveValue(
                        context: context,
                        mobile: 8.0,
                        desktop: 12.0,
                      )),
                      // Должность
                      if (employee.position != null)
                        Text(
                          employee.position!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: ResponsiveUtils.adaptiveValue(
                              context: context,
                              mobile: theme.textTheme.titleMedium?.fontSize ?? 16.0,
                              desktop: (theme.textTheme.titleMedium?.fontSize ?? 16.0) * 1.1,
                            ),
                          ),
                        ),
                      SizedBox(height: ResponsiveUtils.adaptiveValue(
                        context: context,
                        mobile: 8.0,
                        desktop: 12.0,
                      )),
                      // Статус
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          statusText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.adaptiveValue(
                              context: context,
                              mobile: theme.textTheme.bodyMedium?.fontSize ?? 14.0,
                              desktop: (theme.textTheme.bodyMedium?.fontSize ?? 14.0) * 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Табы для разделов информации
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_outline),
                  text: 'Данные',
                ),
                Tab(
                  icon: Icon(Icons.work_outline),
                  text: 'Работа',
                ),
                Tab(
                  icon: Icon(Icons.description_outlined),
                  text: 'Документы',
                ),
              ],
            ),
          ),
          
          // Содержимое табов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка с основной информацией (Данные)
                _buildTabContent([
                  _buildInfoSection(
                    'Личная информация',
                    [
                      _buildInfoItem('Фамилия', employee.lastName, labelStyle, valueStyle),
                      _buildInfoItem('Имя', employee.firstName, labelStyle, valueStyle),
                      _buildInfoItem('Отчество', employee.middleName ?? 'Не указано', labelStyle, valueStyle),
                      _buildInfoItem('Дата рождения', _formatDate(employee.birthDate), labelStyle, valueStyle),
                      _buildInfoItem('Место рождения', employee.birthPlace ?? 'Не указано', labelStyle, valueStyle),
                      _buildInfoItem('Гражданство', employee.citizenship ?? 'Не указано', labelStyle, valueStyle),
                      _buildInfoItem('Телефон', employee.phone ?? 'Не указан', labelStyle, valueStyle),
                    ],
                    sectionTitleStyle,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _buildInfoSection(
                    'Физические параметры',
                    [
                      _buildInfoItem('Рост', employee.height ?? 'Не указан', labelStyle, valueStyle),
                      _buildInfoItem('Размер одежды', employee.clothingSize ?? 'Не указан', labelStyle, valueStyle),
                      _buildInfoItem('Размер обуви', employee.shoeSize ?? 'Не указан', labelStyle, valueStyle),
                    ],
                    sectionTitleStyle,
                    icon: Icons.accessibility_new,
                  ),
                ]),
                
                // Вкладка с информацией о работе
                _buildTabContent([
                  _buildInfoSection(
                    'Информация о работе',
                    [
                      _buildInfoItem('Должность', employee.position ?? 'Не указана', labelStyle, valueStyle),
                      _buildInfoItem('Дата трудоустройства', _formatDate(employee.employmentDate), labelStyle, valueStyle),
                      _buildInfoItem('Вид трудоустройства', employmentTypeText, labelStyle, valueStyle),
                      _buildInfoItem('Ставка (руб/час)', 
                        employee.hourlyRate != null ? '${employee.hourlyRate} ₽/час' : 'Не указана',
                        labelStyle, valueStyle,
                      ),
                      _buildInfoItem('Объекты', objectsText, labelStyle, valueStyle),
                      _buildInfoItem('Статус', statusText, labelStyle, valueStyle, 
                        valueColor: statusColor,
                      ),
                    ],
                    sectionTitleStyle,
                    icon: Icons.work,
                  ),
                ]),
                
                // Вкладка с документами
                _buildTabContent([
                  _buildInfoSection(
                    'Паспортные данные',
                    [
                      _buildInfoItem('Серия', employee.passportSeries ?? 'Не указана', labelStyle, valueStyle),
                      _buildInfoItem('Номер', employee.passportNumber ?? 'Не указан', labelStyle, valueStyle),
                      _buildInfoItem('Кем выдан', employee.passportIssuedBy ?? 'Не указано', labelStyle, valueStyle),
                      _buildInfoItem('Дата выдачи', _formatDate(employee.passportIssueDate), labelStyle, valueStyle),
                      _buildInfoItem('Код подразделения', employee.passportDepartmentCode ?? 'Не указан', labelStyle, valueStyle),
                      _buildInfoItem('Адрес регистрации', employee.registrationAddress ?? 'Не указан', labelStyle, valueStyle),
                    ],
                    sectionTitleStyle,
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _buildInfoSection(
                    'Дополнительные документы',
                    [
                      _buildInfoItem('ИНН', employee.inn ?? 'Не указан', labelStyle, valueStyle),
                      _buildInfoItem('СНИЛС', employee.snils ?? 'Не указан', labelStyle, valueStyle),
                    ],
                    sectionTitleStyle,
                    icon: Icons.assignment,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Обертка для содержимого вкладки с общим отступом и прокруткой
  Widget _buildTabContent(List<Widget> children) {
    return ListView(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding(context)),
      children: children,
    );
  }
  
  // Построение секции с информацией
  Widget _buildInfoSection(String title, List<Widget> items, TextStyle? titleStyle, {IconData? icon}) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
      ),
      child: Padding(
        padding: ResponsiveUtils.getAdaptiveInsets(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(title, style: titleStyle),
              ],
            ),
            const Divider(height: 32),
            ...items,
          ],
        ),
      ),
    );
  }
  
  // Построение элемента с информацией
  Widget _buildInfoItem(String label, String value, TextStyle labelStyle, TextStyle valueStyle, {Color? valueColor}) {
    // Адаптивная ширина метки
    final double adaptiveLabelWidth = ResponsiveUtils.adaptiveValue(
      context: context,
      mobile: _labelWidth,
      desktop: _labelWidth * 1.2,
    );
    
    final theme = Theme.of(context);
    final bool isLargeValue = value.length > 30;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.adaptiveValue(context: context, mobile: 12.0, desktop: 16.0)),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isLargeValue 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: labelStyle.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  value, 
                  style: valueColor != null 
                    ? valueStyle.copyWith(color: valueColor)
                    : valueStyle,
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: adaptiveLabelWidth - 12, // учитываем отступ для вертикальной полосы
                child: Text(label, style: labelStyle.copyWith(fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Text(
                  value, 
                  style: valueColor != null 
                    ? valueStyle.copyWith(color: valueColor)
                    : valueStyle,
                ),
              ),
            ],
          ),
    );
  }
  
  /// Показывает диалог подтверждения удаления.
  Future<void> _showDeleteDialog(Employee employee) async {
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удалить сотрудника?',
      message: 'Вы уверены, что хотите удалить этого сотрудника?',
      onConfirm: () {},
    );
    
    if (confirmed == true) {
      try {
        await ref.read(state.employeeProvider.notifier).deleteEmployee(employee.id);
        if (!mounted) return;
          NotificationsService.showErrorNotification(context, 'Сотрудник удалён');
          if (widget.showAppBar) {
            context.pop();
        }
      } catch (e) {
        if (!mounted) return;
          NotificationsService.showErrorNotification(context, 'Ошибка удаления: ${e.toString()}');
      }
    }
  }
} 

/// Расширение для удобного создания цвета с изменёнными компонентами.
extension ColorExtension on Color {
  /// Возвращает новый цвет с изменёнными компонентами (r, g, b, a).
  ///
  /// [red], [green], [blue] — новые значения каналов (0..255), если не указаны — берутся из исходного цвета.
  /// [alpha] — новый альфа-канал (0.0..1.0), если не указан — берётся из исходного цвета.
  Color withValues({
    int? red,
    int? green,
    int? blue,
    double? alpha,
  }) {
    return Color.fromRGBO(
      (red ?? r).toInt(),
      (green ?? g).toInt(),
      (blue ?? b).toInt(),
      (alpha ?? a).toDouble(),
    );
  }
} 