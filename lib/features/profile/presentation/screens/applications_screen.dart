import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'vacation_form_bottom_sheet.dart';
import 'unpaid_leave_form_bottom_sheet.dart';

/// Экран с заявлениями сотрудников.
///
/// Предоставляет доступ к различным типам заявлений:
/// - Заявление на отпуск (ежегодный оплачиваемый)
/// - Заявление на отпуск без сохранения заработной платы
/// - Заявление на увольнение по собственному желанию
/// - Заявление на перевод на другую должность
/// - Заявление на материальную помощь
/// - Заявление на командировку
/// - Заявление на изменение графика работы
class ApplicationsScreen extends ConsumerStatefulWidget {
  /// Создаёт экран заявлений.
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF1C1C1E),
      appBar: const AppBarWidget(
        title: 'Заявления',
        leading: BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок секции
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                'ТИПЫ ЗАЯВЛЕНИЙ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Группа заявлений
            _ApplicationMenuGroup(
              children: [
                _ApplicationMenuItem(
                  icon: Icons.beach_access_outlined,
                  iconColor: Colors.blue,
                  title: 'Отпуск',
                  subtitle: 'Заявление на ежегодный оплачиваемый отпуск',
                  onTap: () => _showVacationForm(context, profile),
                ),
                _ApplicationMenuItem(
                  icon: Icons.event_busy_outlined,
                  iconColor: Colors.purple,
                  title: 'Отпуск без содержания',
                  subtitle:
                      'Заявление на отпуск без сохранения заработной платы',
                  onTap: () => _showUnpaidLeaveForm(context, profile),
                ),
                const _ApplicationMenuItem(
                  icon: Icons.logout_outlined,
                  iconColor: Colors.red,
                  title: 'Увольнение',
                  subtitle: 'Заявление на увольнение по собственному желанию',
                ),
                const _ApplicationMenuItem(
                  icon: Icons.swap_horiz_outlined,
                  iconColor: Colors.green,
                  title: 'Перевод на другую должность',
                  subtitle: 'Заявление на перевод на другую должность',
                ),
                const _ApplicationMenuItem(
                  icon: Icons.attach_money_outlined,
                  iconColor: Colors.orange,
                  title: 'Материальная помощь',
                  subtitle: 'Заявление на получение материальной помощи',
                ),
                const _ApplicationMenuItem(
                  icon: Icons.flight_takeoff_outlined,
                  iconColor: Colors.teal,
                  title: 'Командировка',
                  subtitle: 'Заявление на служебную командировку',
                ),
                const _ApplicationMenuItem(
                  icon: Icons.schedule_outlined,
                  iconColor: Colors.indigo,
                  title: 'Изменение графика работы',
                  subtitle: 'Заявление на изменение графика работы',
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Информационная карточка
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Информация',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Все заявления будут автоматически направляться на согласование руководителю. Заявления в разработке по одному будут добавляться функциональностью.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Показывает форму заявления об отпуске в bottom sheet
  void _showVacationForm(BuildContext context, dynamic profile) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VacationFormBottomSheet(
        profile: profile,
        position: profile?.position,
      ),
    );
  }

  /// Показывает форму заявления на отпуск без сохранения заработной платы в bottom sheet
  void _showUnpaidLeaveForm(BuildContext context, dynamic profile) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UnpaidLeaveFormBottomSheet(
        profile: profile,
        position: profile?.position,
      ),
    );
  }
}

/// Объединяет несколько [_ApplicationMenuItem] в одну карточку с закругленными углами.
class _ApplicationMenuGroup extends StatelessWidget {
  /// Список элементов меню внутри группы.
  final List<Widget> children;

  /// Создаёт группу элементов меню.
  const _ApplicationMenuGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  /// Добавляет разделители между элементами списка.
  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Элемент меню заявления в стиле Apple Settings.
///
/// Отображает иконку, заголовок, опциональный подзаголовок и стрелку вправо.
class _ApplicationMenuItem extends StatelessWidget {
  /// Иконка элемента.
  final IconData icon;

  /// Цвет иконки.
  final Color iconColor;

  /// Основной текст элемента.
  final String title;

  /// Дополнительный текст под заголовком (опционально).
  final String? subtitle;

  /// Коллбэк при нажатии.
  final VoidCallback? onTap;

  /// Создаёт элемент меню в стиле Apple.
  const _ApplicationMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Иконка в цветном квадратике
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          // Стрелка (только если есть onTap)
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return _ApplicationTapEffect(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Виджет для создания iOS-подобного эффекта затемнения при нажатии.
///
/// При нажатии элемент затемняется серым фоном, как в iOS Settings.
class _ApplicationTapEffect extends StatefulWidget {
  /// Дочерний виджет.
  final Widget child;

  /// Коллбэк при нажатии.
  final VoidCallback onTap;

  /// Создаёт виджет с iOS-подобным эффектом нажатия.
  const _ApplicationTapEffect({
    required this.child,
    required this.onTap,
  });

  @override
  State<_ApplicationTapEffect> createState() => _ApplicationTapEffectState();
}

/// Состояние для [_ApplicationTapEffect].
class _ApplicationTapEffectState extends State<_ApplicationTapEffect> {
  /// Флаг нажатия.
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
