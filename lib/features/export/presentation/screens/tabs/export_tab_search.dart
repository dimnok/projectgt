import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import '../../providers/work_search_provider.dart';
import '../../widgets/export_search_action.dart';
import '../../../domain/entities/work_search_result.dart';

/// Таб "Поиск" для расширенного поиска и фильтрации данных.
class ExportTabSearch extends ConsumerStatefulWidget {
  /// Создаёт таб поиска.
  const ExportTabSearch({super.key});

  @override
  ConsumerState<ExportTabSearch> createState() => _ExportTabSearchState();
}

class _ExportTabSearchState extends ConsumerState<ExportTabSearch>
    with SingleTickerProviderStateMixin {
  /// Контроллер для вертикального скролла таблицы.
  final ScrollController _verticalController = ScrollController();

  /// Контроллер анимации стрелки.
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _arrowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _arrowAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _arrowAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, является ли устройство десктопом
    if (!ResponsiveUtils.isDesktop(context)) {
      return _buildMobileUnavailableMessage(context);
    }

    final theme = Theme.of(context);
    final searchState = ref.watch(workSearchProvider);
    final searchQuery = ref.watch(exportSearchQueryProvider);
    final selectedObjectId = ref.watch(exportSelectedObjectIdProvider);

    return _buildSearchResults(
        context, theme, searchState, searchQuery, selectedObjectId);
  }

  /// Строит сообщение о недоступности модуля на мобильных устройствах.
  Widget _buildMobileUnavailableMessage(BuildContext context) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка компьютера
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.desktop_windows_rounded,
                size: 80,
                color: isLightTheme ? Colors.blue : Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 32),
            // Заголовок
            Text(
              'Модуль доступен только на компьютере',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Описание
            Text(
              'Расширенный поиск и фильтрация данных требуют большого экрана для комфортной работы. Мобильная версия находится в разработке.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Дополнительная информация
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isLightTheme ? Colors.blue : Colors.blue.shade300,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Используйте компьютер или планшет с шириной экрана более 900px для доступа к этому модулю.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит подсказку для выбора объекта с анимацией.
  Widget _buildObjectSelectionPrompt(BuildContext context, ThemeData theme) {
    final isLightTheme = theme.brightness == Brightness.light;

    return Stack(
      children: [
        // Основной контент
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80), // Отступ для стрелки сверху
                // Иконка объекта
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLightTheme
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 64,
                    color: isLightTheme ? Colors.blue : Colors.blue.shade300,
                  ),
                ),
                const SizedBox(height: 32),
                // Заголовок
                Text(
                  'Выберите объект для начала поиска',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Описание логики работы
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLightTheme
                        ? Colors.grey.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: isLightTheme
                                ? Colors.blue
                                : Colors.blue.shade300,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Как это работает:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStepItem(
                        context,
                        theme,
                        '1',
                        'Выберите объект из чипов выше',
                        Icons.filter_alt_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        theme,
                        '2',
                        'Используйте поиск для фильтрации по наименованию работ',
                        Icons.search_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        theme,
                        '3',
                        'Применяйте фильтры по системе, участку и этажу',
                        Icons.tune_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        theme,
                        '4',
                        'Просматривайте и редактируйте результаты в таблице',
                        Icons.table_chart_rounded,
                      ),
                      const SizedBox(height: 16),
                      // Дополнительная информация о функциях
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? Colors.blue.withValues(alpha: 0.05)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLightTheme
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: isLightTheme
                                      ? Colors.blue.shade700
                                      : Colors.blue.shade300,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Полезные функции:',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isLightTheme
                                        ? Colors.blue.shade700
                                        : Colors.blue.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTipItem(
                              context,
                              theme,
                              'Нажмите на наименование материала в таблице — оно автоматически вставится в поле поиска и выполнится фильтрация',
                              Icons.touch_app_rounded,
                            ),
                            const SizedBox(height: 6),
                            _buildTipItem(
                              context,
                              theme,
                              'Строка "ИТОГО" появляется только когда все наименования одинаковы — это позволяет подсчитать количество конкретного материала',
                              Icons.calculate_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Описание работы фильтров
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLightTheme
                              ? Colors.green.withValues(alpha: 0.05)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLightTheme
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  size: 16,
                                  color: isLightTheme
                                      ? Colors.green.shade700
                                      : Colors.green.shade300,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Работа с фильтрами:',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isLightTheme
                                        ? Colors.green.shade700
                                        : Colors.green.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTipItem(
                              context,
                              theme,
                              'После выбора объекта выберите систему — будет отображён весь материал, который был использован в сменах этой системы',
                              Icons.category_rounded,
                            ),
                            const SizedBox(height: 6),
                            _buildTipItem(
                              context,
                              theme,
                              'Выберите участок — получите данные по выбранному участку. Добавьте этаж — сможете отследить работы на конкретном участке и этаже',
                              Icons.location_on_rounded,
                            ),
                            const SizedBox(height: 6),
                            _buildTipItem(
                              context,
                              theme,
                              'Введите или выберите наименование материала в поиске — в таблице будет информация где применялся материал: в каких системах, участках и этажах',
                              Icons.search_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Миниатюра таблицы для визуализации
                _buildTablePreview(context, theme),
                const SizedBox(height: 24),
                // Подсказка о чипах
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isLightTheme
                        ? Colors.blue.withValues(alpha: 0.08)
                        : Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 20,
                        color:
                            isLightTheme ? Colors.blue : Colors.blue.shade300,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Нажмите на чип объекта выше для начала работы',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLightTheme
                              ? Colors.blue.shade700
                              : Colors.blue.shade300,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Анимированная стрелка, указывающая на чипы объектов сверху слева
        Positioned(
          top: 0,
          left: 24, // Отступ слева, чтобы указать на чипы объектов
          child: AnimatedBuilder(
            animation: _arrowAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -15 * (1 - _arrowAnimation.value)),
                child: Opacity(
                  opacity: 0.4 + (_arrowAnimation.value * 0.6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLightTheme
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 32,
                      color: isLightTheme
                          ? Colors.blue.shade700
                          : Colors.blue.shade300,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Строит миниатюру таблицы для визуализации результатов.
  Widget _buildTablePreview(BuildContext context, ThemeData theme) {
    final isLightTheme = theme.brightness == Brightness.light;
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerBackgroundColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.table_chart_rounded,
                size: 20,
                color: isLightTheme ? Colors.blue : Colors.blue.shade300,
              ),
              const SizedBox(width: 8),
              Text(
                'Пример результатов поиска',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Миниатюра AppBar с полем поиска
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Поиск по наименованию...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Миниатюрная таблица
          Table(
            border: TableBorder(
              top: BorderSide(color: dividerColor, width: 1),
              bottom: BorderSide(color: dividerColor, width: 1),
              left: BorderSide(color: dividerColor, width: 1),
              right: BorderSide(color: dividerColor, width: 1),
              horizontalInside: BorderSide(color: dividerColor, width: 1),
              verticalInside: BorderSide(color: dividerColor, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(), // Дата
              1: IntrinsicColumnWidth(), // Объект
              2: IntrinsicColumnWidth(), // Система
              3: IntrinsicColumnWidth(), // Подсистема
              4: IntrinsicColumnWidth(), // Участок
              5: IntrinsicColumnWidth(), // Этаж
              6: FlexColumnWidth(1), // Наименование материала
              7: IntrinsicColumnWidth(), // Ед.
              8: IntrinsicColumnWidth(), // Кол-во
            },
            children: [
              // Заголовок
              TableRow(
                decoration: BoxDecoration(color: headerBackgroundColor),
                children: [
                  _buildPreviewCell('Дата', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Объект', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Система', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Подсистема', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Участок', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Этаж', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Материал', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Ед.', theme, TextAlign.center,
                      isHeader: true),
                  _buildPreviewCell('Кол-во', theme, TextAlign.center,
                      isHeader: true),
                ],
              ),
              // Пример строки 1
              TableRow(
                children: [
                  _buildPreviewCell('15.01', theme, TextAlign.center),
                  _buildPreviewCell('Объект 1', theme, TextAlign.left),
                  _buildPreviewCell('Водоснабжение', theme, TextAlign.center),
                  _buildPreviewCell('ХВС', theme, TextAlign.center),
                  _buildPreviewCell('А', theme, TextAlign.center),
                  _buildPreviewCell('1', theme, TextAlign.center),
                  _buildPreviewCell('Труба ПНД...', theme, TextAlign.left),
                  _buildPreviewCell('м', theme, TextAlign.center),
                  _buildPreviewCell('125', theme, TextAlign.center),
                ],
              ),
              // Пример строки 2
              TableRow(
                children: [
                  _buildPreviewCell('14.01', theme, TextAlign.center),
                  _buildPreviewCell('Объект 1', theme, TextAlign.left),
                  _buildPreviewCell('Электрика', theme, TextAlign.center),
                  _buildPreviewCell('Освещение', theme, TextAlign.center),
                  _buildPreviewCell('Б', theme, TextAlign.center),
                  _buildPreviewCell('2', theme, TextAlign.center),
                  _buildPreviewCell('Кабель ВВГ...', theme, TextAlign.left),
                  _buildPreviewCell('м', theme, TextAlign.center),
                  _buildPreviewCell('85', theme, TextAlign.center),
                ],
              ),
              // Итоговая строка (если все материалы одинаковые)
              TableRow(
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? Colors.blue.withValues(alpha: 0.2)
                      : theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                ),
                children: [
                  _buildPreviewCell('ИТОГО', theme, TextAlign.center,
                      isTotal: true),
                  _buildPreviewCell('', theme, TextAlign.left),
                  _buildPreviewCell('', theme, TextAlign.center),
                  _buildPreviewCell('', theme, TextAlign.center),
                  _buildPreviewCell('', theme, TextAlign.center),
                  _buildPreviewCell('', theme, TextAlign.center),
                  _buildPreviewCell('', theme, TextAlign.left),
                  _buildPreviewCell('', theme, TextAlign.center),
                  _buildPreviewCell('210', theme, TextAlign.center,
                      isTotal: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Строит ячейку для миниатюры таблицы.
  Widget _buildPreviewCell(
    String text,
    ThemeData theme,
    TextAlign align, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    final isLightTheme = theme.brightness == Brightness.light;
    Alignment cellAlignment;
    switch (align) {
      case TextAlign.center:
        cellAlignment = Alignment.center;
        break;
      case TextAlign.right:
        cellAlignment = Alignment.centerRight;
        break;
      default:
        cellAlignment = Alignment.centerLeft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: cellAlignment,
      child: Text(
        text,
        style: isHeader
            ? theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              )
            : isTotal
                ? theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isLightTheme ? Colors.green : theme.colorScheme.primary,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Строит элемент подсказки с иконкой.
  Widget _buildTipItem(
    BuildContext context,
    ThemeData theme,
    String text,
    IconData icon,
  ) {
    final isLightTheme = theme.brightness == Brightness.light;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isLightTheme ? Colors.blue.shade600 : Colors.blue.shade300,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.4,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Строит элемент шага инструкции.
  Widget _buildStepItem(
    BuildContext context,
    ThemeData theme,
    String stepNumber,
    String description,
    IconData icon,
  ) {
    final isLightTheme = theme.brightness == Brightness.light;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isLightTheme
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                color:
                    isLightTheme ? Colors.blue.shade700 : Colors.blue.shade300,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Строит результаты поиска.
  Widget _buildSearchResults(
    BuildContext context,
    ThemeData theme,
    WorkSearchState searchState,
    String searchQuery,
    String? selectedObjectId,
  ) {
    if (searchState.isLoading) {
      final isLightTheme = theme.brightness == Brightness.light;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(
                radius: 15,
                color: isLightTheme ? Colors.green : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Загрузка данных...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                searchState.error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Объект обязателен для поиска
    if (selectedObjectId == null) {
      return _buildObjectSelectionPrompt(context, theme);
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Ничего не найдено',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте выбрать другой объект или изменить запрос поиска',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: _buildResultsTable(
                context, theme, searchState.results, searchState),
          ),
          if (searchState.totalPages > 1)
            _buildPaginationControls(context, theme, searchState),
        ],
      ),
    );
  }

  /// Строит таблицу результатов.
  Widget _buildResultsTable(BuildContext context, ThemeData theme,
      List<WorkSearchResult> results, WorkSearchState searchState) {
    // Данные уже отсортированы по дате в DataSource (новые сверху)
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerBackgroundColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    Widget headerCell(String text, {TextAlign align = TextAlign.left}) {
      Alignment headerAlignment;
      switch (align) {
        case TextAlign.center:
          headerAlignment = Alignment.center;
          break;
        case TextAlign.right:
          headerAlignment = Alignment.centerRight;
          break;
        default:
          headerAlignment = Alignment.centerLeft;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: headerAlignment,
        child: Text(
          text,
          textAlign: align,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget bodyCell(
      Widget child, {
      Alignment align = Alignment.centerLeft,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: align,
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!,
          child: child,
        ),
      );
    }

    List<TableRow> buildRows() {
      final list = <TableRow>[];

      // Заголовок
      list.add(
        TableRow(
          decoration: BoxDecoration(color: headerBackgroundColor),
          children: [
            headerCell('Дата смены', align: TextAlign.center),
            headerCell('Объект', align: TextAlign.center),
            headerCell('Система', align: TextAlign.center),
            headerCell('Подсистема', align: TextAlign.center),
            headerCell('Участок', align: TextAlign.center),
            headerCell('Этаж', align: TextAlign.center),
            headerCell('Наименование материала', align: TextAlign.center),
            headerCell('Ед. изм.', align: TextAlign.center),
            headerCell('Кол-во', align: TextAlign.center),
            headerCell('Цена', align: TextAlign.center),
            headerCell('Сумма', align: TextAlign.center),
          ],
        ),
      );

      // Проверяем, все ли результаты имеют одинаковое наименование материала
      final allSameMaterial = results.isNotEmpty &&
          results.every((r) => r.materialName == results.first.materialName);

      // Подсчет общего количества (только если все материалы одинаковые)
      final totalQuantity = allSameMaterial
          ? results.fold<num>(0, (sum, result) => sum + result.quantity)
          : 0;

      // Строки данных
      for (final result in results) {
        list.add(
          TableRow(
            children: [
              bodyCell(
                Builder(
                  builder: (cellContext) => GestureDetector(
                    onLongPress: () {
                      // Проверка наличия необходимых данных
                      if (result.workId == null) {
                        SnackBarUtils.showError(
                          cellContext,
                          'Недостаточно данных для выполнения действия',
                        );
                        return;
                      }

                      // Показываем меню выбора действия
                      ModalUtils.showExportWorkItemActionDialog(
                        cellContext,
                        initialData: result,
                        onEdit: () {
                          // Проверка роли админа
                          final isAdmin =
                              ref.read(authProvider).user?.role == 'admin';

                          // Проверка статуса смены (только для не-админов)
                          if (!isAdmin &&
                              result.workStatus?.toLowerCase() != 'open') {
                            SnackBarUtils.showError(
                              cellContext,
                              'Нельзя редактировать закрытую смену',
                            );
                            return;
                          }

                          // Проверка наличия необходимых данных для редактирования
                          if (result.workItemId == null ||
                              result.workId == null ||
                              result.objectId == null) {
                            SnackBarUtils.showError(
                              cellContext,
                              'Недостаточно данных для редактирования',
                            );
                            return;
                          }

                          // Открываем модальное окно редактирования
                          ModalUtils.showExportWorkItemEditModal(
                            cellContext,
                            initialData: result,
                          );
                        },
                        onNavigateToWork: () {
                          // Переходим к смене
                          if (result.workId != null) {
                            cellContext.goNamed(
                              'work_details',
                              pathParameters: {'workId': result.workId!},
                            );
                          }
                        },
                      );
                    },
                    child: Text(formatRuDate(result.workDate)),
                  ),
                ),
                align: Alignment.center,
              ),
              bodyCell(Text(result.objectName)),
              bodyCell(
                Text(result.system),
                align: Alignment.center,
              ),
              bodyCell(
                Text(result.subsystem),
                align: Alignment.center,
              ),
              bodyCell(
                Text(result.section),
                align: Alignment.center,
              ),
              bodyCell(
                Text(result.floor),
                align: Alignment.center,
              ),
              bodyCell(
                GestureDetector(
                  onTap: () {
                    // Вставляем наименование в поле поиска
                    ref.read(exportSearchQueryProvider.notifier).state =
                        result.materialName;
                    // Показываем поле поиска, если оно скрыто
                    ref.read(exportSearchVisibleProvider.notifier).state = true;
                    // Запускаем поиск
                    final selectedObjectId =
                        ref.read(exportSelectedObjectIdProvider);
                    final filters = ref.read(exportSearchFilterProvider);
                    ref.read(workSearchProvider.notifier).searchMaterials(
                          objectId: selectedObjectId,
                          searchQuery: result.materialName,
                          systemFilters: filters['system']?.toList(),
                          sectionFilters: filters['section']?.toList(),
                          floorFilters: filters['floor']?.toList(),
                        );
                  },
                  child: Text(result.materialName),
                ),
              ),
              bodyCell(
                Text(result.unit),
                align: Alignment.center,
              ),
              bodyCell(
                Text(result.quantity.toString()),
                align: Alignment.center,
              ),
              bodyCell(
                Text(
                  result.price != null ? formatCurrency(result.price!) : '—',
                ),
                align: Alignment.centerRight,
              ),
              bodyCell(
                Text(
                  result.total != null ? formatCurrency(result.total!) : '—',
                ),
                align: Alignment.centerRight,
              ),
            ],
          ),
        );
      }

      // Итоговая строка (только если все материалы одинаковые)
      if (allSameMaterial) {
        final isLightTheme = theme.brightness == Brightness.light;
        final totalTextColor =
            isLightTheme ? Colors.green : theme.colorScheme.primary;
        final totalBackgroundColor = isLightTheme
            ? Colors.blue.withValues(alpha: 0.2)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        list.add(
          TableRow(
            decoration: BoxDecoration(
              color: totalBackgroundColor,
            ),
            children: [
              bodyCell(
                Text(
                  'ИТОГО',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalTextColor,
                  ),
                ),
                align: Alignment.center,
              ),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
              bodyCell(
                Text(
                  totalQuantity.toString(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalTextColor,
                  ),
                ),
                align: Alignment.center,
              ),
              bodyCell(const Text('')),
              bodyCell(const Text('')),
            ],
          ),
        );
      }

      return list;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Table(
                border: TableBorder(
                  top: BorderSide(color: dividerColor, width: 1),
                  bottom: BorderSide(color: dividerColor, width: 1),
                  left: BorderSide(color: dividerColor, width: 1),
                  right: BorderSide(color: dividerColor, width: 1),
                  horizontalInside: BorderSide(color: dividerColor, width: 1),
                  verticalInside: BorderSide(color: dividerColor, width: 1),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const <int, TableColumnWidth>{
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                  3: IntrinsicColumnWidth(),
                  4: IntrinsicColumnWidth(),
                  5: IntrinsicColumnWidth(),
                  6: FlexColumnWidth(1),
                  7: IntrinsicColumnWidth(),
                  8: IntrinsicColumnWidth(),
                  9: IntrinsicColumnWidth(),
                  10: IntrinsicColumnWidth(),
                },
                children: buildRows(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Строит элементы управления пагинацией.
  Widget _buildPaginationControls(
      BuildContext context, ThemeData theme, WorkSearchState searchState) {
    final canGoPrevious = searchState.currentPage > 1;
    final canGoNext = searchState.currentPage < searchState.totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoPrevious
                ? () => ref.read(workSearchProvider.notifier).previousPage()
                : null,
            tooltip: 'Предыдущая страница',
          ),
          const SizedBox(width: 8),
          Text(
            'Страница ${searchState.currentPage} из ${searchState.totalPages}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${searchState.totalCount} записей)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext
                ? () => ref.read(workSearchProvider.notifier).nextPage()
                : null,
            tooltip: 'Следующая страница',
          ),
        ],
      ),
    );
  }
}
