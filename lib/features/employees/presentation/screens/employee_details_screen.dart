import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

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
  ConsumerState<EmployeeDetailsScreen> createState() =>
      _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends ConsumerState<EmployeeDetailsScreen> {
  int _selectedTab = 0;

  // Константные значения для повторяющихся отступов
  static const double _contentPadding = 16.0;
  static const double _sectionSpacing = 16.0;
  static const double _labelWidth = 150.0;

  Color _canBeResponsibleColor(WidgetRef ref, String employeeId) {
    final map = ref.read(state.employeeProvider).canBeResponsibleMap;
    final isOn = map[employeeId] == true;
    return isOn ? Colors.green : Colors.red;
  }

  @override
  void initState() {
    super.initState();

    // Загружаем данные сотрудника
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(state.employeeProvider.notifier).getEmployee(widget.employeeId);
      // Также подтягиваем фактический флаг can_be_responsible в мапу
      // чтобы цвет щита соответствовал БД при первом открытии
      ref.read(state.employeeProvider.notifier).refreshEmployees();
    });
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
    final isLoading = employee == null &&
        employeeState.status == state.EmployeeStatus.loading;
    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;

    if (isLoading) {
      return Scaffold(
        appBar: widget.showAppBar
            ? const AppBarWidget(title: 'Информация о сотруднике')
            : null,
        drawer: widget.showAppBar
            ? const AppDrawer(activeRoute: AppRoute.employees)
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (employee == null) {
      return Scaffold(
        appBar: widget.showAppBar
            ? const AppBarWidget(title: 'Информация о сотруднике')
            : null,
        drawer: widget.showAppBar
            ? const AppDrawer(activeRoute: AppRoute.employees)
            : null,
        body: Center(
          child: Text(
            'Сотрудник не найден',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Получаем данные для отображения только один раз
    final (statusText, statusColor) =
        EmployeeUIUtils.getStatusInfo(employee.status);
    final employmentTypeText =
        EmployeeUIUtils.getEmploymentTypeText(employee.employmentType);
    // Получаем имена объектов по objectIds
    String objectsText = 'Не указаны';
    if (employee.objectIds.isNotEmpty) {
      final names = employee.objectIds
          .map((id) => objects
              .firstWhere(
                (o) => o.id == id,
                orElse: () =>
                    const ObjectEntity(id: '', name: '—', address: ''),
              )
              .name)
          .where((name) => name != '—')
          .toList();
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

    // Общий стиль для заголовков секций
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    // Общий стиль для меток
    final labelStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: ResponsiveUtils.adaptiveValue(
          context: context, mobile: 14.0, desktop: 15.0),
    );

    // Общий стиль для значений
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: ResponsiveUtils.adaptiveValue(
          context: context, mobile: 15.0, desktop: 16.0),
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBarWidget(
              title: '${employee.lastName} ${employee.firstName}',
              leading: const BackButton(),
              showThemeSwitch: false,
              actions: [
                // Тоггл "Может быть ответственным"
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    Icons.verified_user,
                    color: _canBeResponsibleColor(ref, employee.id),
                  ),
                  onPressed: () async {
                    final current = ref.read(state.employeeProvider).employee;
                    if (current == null) return;
                    // Кэшируем messenger до await согласно правилам безопасного использования BuildContext
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(state.employeeProvider.notifier)
                          .toggleCanBeResponsible(current.id, null);
                      if (!mounted) return;
                      final isOn = ref
                              .read(state.employeeProvider)
                              .canBeResponsibleMap[current.id] ==
                          true;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(isOn
                              ? 'Назначен статус ответственного'
                              : 'Снят статус ответственного'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(Icons.edit, color: Colors.amber),
                  onPressed: () {
                    ModalUtils.showEmployeeFormModal(context,
                        employeeId: employee.id);
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(employee),
                ),
              ],
            )
          : null,
      drawer: null,
      body: Column(
        children: [
          // Отступ сверху для мастер-детейл режима (когда AppBar скрыт)
          if (!widget.showAppBar)
            SizedBox(
              height:
                  MediaQuery.of(context).viewPadding.top + kToolbarHeight + 24,
            ),
          // Отступ сверху как в списке сотрудников
          SizedBox(
            height: ResponsiveUtils.isMobile(context) ? 8 : 6,
          ),
          // Единый блок с информацией и табами
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.isMobile(context) ? 16 : 0,
            ),
            constraints: ResponsiveUtils.isMobile(context)
                ? BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  )
                : null,
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
              children: [
                // Шапка с фото и основной информацией
                Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.adaptiveValue(
                    context: context,
                    mobile: _contentPadding,
                    desktop: _contentPadding * 1.5,
                  )),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Фото сотрудника
                      Hero(
                        tag: 'employee_avatar_${employee.id}',
                        child: GestureDetector(
                          onTap: employee.photoUrl != null
                              ? () => _showPhotoViewer(context, employee)
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow
                                      .withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: theme.colorScheme.surface,
                              child: employee.photoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: employee.photoUrl!,
                                      imageBuilder: (context, imageProvider) =>
                                          CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundImage: imageProvider,
                                      ),
                                      placeholder: (context, url) => SizedBox(
                                        width: avatarRadius / 2,
                                        height: avatarRadius / 2,
                                        child: const CircularProgressIndicator
                                            .adaptive(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundColor: theme
                                            .colorScheme.surface
                                            .withValues(alpha: 0.1),
                                        child: Icon(
                                          Icons.person,
                                          size: avatarRadius,
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: avatarRadius,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
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
                                  mobile:
                                      theme.textTheme.titleLarge?.fontSize ??
                                          22.0,
                                  desktop:
                                      (theme.textTheme.titleLarge?.fontSize ??
                                              22.0) *
                                          1.2,
                                ),
                              ),
                            ),
                            SizedBox(
                                height: ResponsiveUtils.adaptiveValue(
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
                                    mobile:
                                        theme.textTheme.titleMedium?.fontSize ??
                                            16.0,
                                    desktop: (theme.textTheme.titleMedium
                                                ?.fontSize ??
                                            16.0) *
                                        1.1,
                                  ),
                                ),
                              ),
                            SizedBox(
                                height: ResponsiveUtils.adaptiveValue(
                              context: context,
                              mobile: 8.0,
                              desktop: 12.0,
                            )),
                            // Статус
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtils.adaptiveValue(
                                    context: context,
                                    mobile:
                                        theme.textTheme.bodyMedium?.fontSize ??
                                            14.0,
                                    desktop:
                                        (theme.textTheme.bodyMedium?.fontSize ??
                                                14.0) *
                                            1.1,
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

                // Разделитель
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),

                // Табы для разделов информации
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedTab,
                    backgroundColor:
                        theme.colorScheme.surface.withValues(alpha: 0.5),
                    thumbColor:
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(4),
                    onValueChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _selectedTab = value;
                        });
                      }
                    },
                    children: {
                      0: SizedBox(
                        width: 110,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: _selectedTab == 0
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Данные',
                                  style: TextStyle(
                                    color: _selectedTab == 0
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                    fontWeight: _selectedTab == 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      1: SizedBox(
                        width: 110,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 18,
                                color: _selectedTab == 1
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Работа',
                                  style: TextStyle(
                                    color: _selectedTab == 1
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      2: SizedBox(
                        width: 120,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: _selectedTab == 2
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Документы',
                                  style: TextStyle(
                                    color: _selectedTab == 2
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                    fontWeight: _selectedTab == 2
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),

          // Содержимое табов
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                // Вкладка с основной информацией (Данные)
                _buildTabContent([
                  _buildInfoSection(
                    'Личная информация',
                    [
                      _buildInfoItem(
                          'Фамилия', employee.lastName, labelStyle, valueStyle),
                      _buildInfoItem(
                          'Имя', employee.firstName, labelStyle, valueStyle),
                      _buildInfoItem(
                          'Отчество',
                          employee.middleName ?? 'Не указано',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Дата рождения',
                          _formatDate(employee.birthDate),
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Место рождения',
                          employee.birthPlace ?? 'Не указано',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Гражданство',
                          employee.citizenship ?? 'Не указано',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem('Телефон', employee.phone ?? 'Не указан',
                          labelStyle, valueStyle),
                    ],
                    sectionTitleStyle,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _buildInfoSection(
                    'Физические параметры',
                    [
                      _buildInfoItem('Рост', employee.height ?? 'Не указан',
                          labelStyle, valueStyle),
                      _buildInfoItem(
                          'Размер одежды',
                          employee.clothingSize ?? 'Не указан',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Размер обуви',
                          employee.shoeSize ?? 'Не указан',
                          labelStyle,
                          valueStyle),
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
                      _buildInfoItem(
                          'Должность',
                          employee.position ?? 'Не указана',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Дата трудоустройства',
                          _formatDate(employee.employmentDate),
                          labelStyle,
                          valueStyle),
                      _buildInfoItem('Вид трудоустройства', employmentTypeText,
                          labelStyle, valueStyle),
                      _buildInfoItem(
                        'Ставка (руб/час)',
                        employee.hourlyRate != null
                            ? '${employee.hourlyRate} ₽/час'
                            : 'Не указана',
                        labelStyle,
                        valueStyle,
                      ),
                      _buildInfoItem(
                          'Объекты', objectsText, labelStyle, valueStyle),
                      _buildInfoItem(
                        'Статус',
                        statusText,
                        labelStyle,
                        valueStyle,
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
                      _buildInfoItem(
                          'Серия',
                          employee.passportSeries ?? 'Не указана',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Номер',
                          employee.passportNumber ?? 'Не указан',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Кем выдан',
                          employee.passportIssuedBy ?? 'Не указано',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Дата выдачи',
                          _formatDate(employee.passportIssueDate),
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Код подразделения',
                          employee.passportDepartmentCode ?? 'Не указан',
                          labelStyle,
                          valueStyle),
                      _buildInfoItem(
                          'Адрес регистрации',
                          employee.registrationAddress ?? 'Не указан',
                          labelStyle,
                          valueStyle),
                    ],
                    sectionTitleStyle,
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _buildInfoSection(
                    'Дополнительные документы',
                    [
                      _buildInfoItem('ИНН', employee.inn ?? 'Не указан',
                          labelStyle, valueStyle),
                      _buildInfoItem('СНИЛС', employee.snils ?? 'Не указан',
                          labelStyle, valueStyle),
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
  Widget _buildInfoSection(
      String title, List<Widget> items, TextStyle? titleStyle,
      {IconData? icon}) {
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
  Widget _buildInfoItem(
      String label, String value, TextStyle labelStyle, TextStyle valueStyle,
      {Color? valueColor}) {
    // Адаптивная ширина метки
    final double adaptiveLabelWidth = ResponsiveUtils.adaptiveValue(
      context: context,
      mobile: _labelWidth,
      desktop: _labelWidth * 1.2,
    );

    final theme = Theme.of(context);
    final bool isLargeValue = value.length > 30;

    return Container(
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.adaptiveValue(
              context: context, mobile: 12.0, desktop: 16.0)),
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
                    Text(label,
                        style:
                            labelStyle.copyWith(fontWeight: FontWeight.w500)),
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
                  width: adaptiveLabelWidth -
                      12, // учитываем отступ для вертикальной полосы
                  child: Text(label,
                      style: labelStyle.copyWith(fontWeight: FontWeight.w500)),
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
        await ref
            .read(state.employeeProvider.notifier)
            .deleteEmployee(employee.id);
        if (!mounted) return;
        SnackBarUtils.showError(context, 'Сотрудник удалён');
        if (widget.showAppBar) {
          context.pop();
        }
      } catch (e) {
        if (!mounted) return;
        SnackBarUtils.showError(context, 'Ошибка удаления: ${e.toString()}');
      }
    }
  }

  /// Показывает полноэкранный просмотр фото сотрудника.
  void _showPhotoViewer(BuildContext context, Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              '${employee.lastName} ${employee.firstName}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              if (employee.photoUrl != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.cloud_download,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _downloadPhoto(context, employee),
                ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: employee.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: employee.photoUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }

  /// Скачивает фото сотрудника в галерею устройства.
  Future<void> _downloadPhoto(BuildContext context, Employee employee) async {
    if (employee.photoUrl == null) return;

    try {
      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Скачивание фото...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Скачиваем изображение
      final response = await http.get(Uri.parse(employee.photoUrl!));
      if (response.statusCode != 200) {
        throw Exception('Не удалось скачать изображение');
      }

      // Определяем имя файла с полным ФИО и должностью
      final lastName = employee.lastName.trim().isNotEmpty
          ? employee.lastName.trim()
          : 'Неизвестно';
      final firstName = employee.firstName.trim().isNotEmpty
          ? employee.firstName.trim()
          : 'Имя';
      final middleName = employee.middleName?.trim().isNotEmpty == true
          ? '_${employee.middleName!.trim()}'
          : '';
      final position = employee.position?.trim().isNotEmpty == true
          ? '_${employee.position!.trim()}'
          : '';

      final cleanFileName = '${lastName}_$firstName$middleName$position'
          .replaceAll(RegExp(r'[^\w\s\-\._а-яА-Я]', unicode: true),
              '') // Убираем спецсимволы, оставляем кириллицу
          .replaceAll(RegExp(r'\s+'), '_') // Заменяем пробелы на подчеркивания
          .replaceAll(
              RegExp(r'_+'), '_'); // Убираем множественные подчеркивания

      // Финальная проверка и fallback
      final finalFileName = cleanFileName.replaceAll(
          RegExp(r'^_+|_+$'), ''); // Убираем начальные/конечные _
      final safeFileName =
          finalFileName.isNotEmpty ? finalFileName : 'employee';

      if (kIsWeb) {
        // Для веб-платформы
        await FileSaver.instance.saveFile(
          name: safeFileName,
          bytes: response.bodyBytes,
          ext: 'jpg',
          mimeType: MimeType.jpeg,
        );
      } else {
        // Для мобильных и десктопных платформ
        try {
          // Пробуем определить платформу безопасно
          if (Platform.isIOS) {
            // Для iOS - сохраняем в галерею
            await Gal.putImageBytes(
              response.bodyBytes,
              name: safeFileName,
            );
          } else if (Platform.isAndroid) {
            // Для Android
            await FileSaver.instance.saveFile(
              name: safeFileName,
              bytes: response.bodyBytes,
              ext: 'jpg',
              mimeType: MimeType.jpeg,
            );
          } else {
            // Для десктопных платформ - fallback
            throw UnsupportedError('Desktop platform');
          }
        } catch (e) {
          // Fallback для десктопных платформ и любых других ошибок платформы
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            final file = File('${directory.path}/$safeFileName.jpg');
            await file.writeAsBytes(response.bodyBytes);
          } else {
            throw Exception('Не удалось найти папку загрузок');
          }
        }
      }

      // Убираем индикатор загрузки и показываем успех
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();

        String successMessage = 'Фото успешно сохранено';

        if (kIsWeb) {
          successMessage = 'Фото скачано в папку "Загрузки"';
        } else {
          try {
            if (Platform.isIOS) {
              successMessage = 'Фото сохранено в приложение "Фото"';
            } else if (Platform.isAndroid) {
              successMessage = 'Фото сохранено в галерею';
            } else {
              successMessage = 'Фото сохранено в папку "Загрузки"';
            }
          } catch (e) {
            // Fallback для платформ где Platform.isXXX не работает
            successMessage = 'Фото сохранено в папку "Загрузки"';
          }
        }

        SnackBarUtils.showSuccess(
          context,
          successMessage,
        );
      }
    } catch (e) {
      // Убираем индикатор загрузки и показываем ошибку
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        SnackBarUtils.showError(
          context,
          'Ошибка скачивания: ${e.toString()}',
        );
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
