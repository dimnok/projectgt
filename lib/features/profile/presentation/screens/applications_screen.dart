import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/features/profile/presentation/screens/vacation_form_bottom_sheet.dart';
import 'package:projectgt/features/profile/presentation/screens/unpaid_leave_form_bottom_sheet.dart';

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppBarWidget(
        title: 'Заявления',
        leading: BackButton(),
      ),
      body: ContentConstrainedBox(
        child: SingleChildScrollView(
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
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Группа заявлений
              AppleMenuGroup(
                children: [
                  AppleMenuItem(
                    icon: CupertinoIcons.sun_max,
                    iconColor: CupertinoColors.systemBlue,
                    title: 'Отпуск',
                    subtitle: 'Заявление на ежегодный оплачиваемый отпуск',
                    onTap: () => _showVacationForm(context, profile),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.calendar_badge_minus,
                    iconColor: CupertinoColors.systemPurple,
                    title: 'Отпуск без содержания',
                    subtitle:
                        'Заявление на отпуск без сохранения заработной платы',
                    onTap: () => _showUnpaidLeaveForm(context, profile),
                  ),
                  const AppleMenuItem(
                    icon: CupertinoIcons.square_arrow_right,
                    iconColor: CupertinoColors.systemRed,
                    title: 'Увольнение',
                    subtitle: 'Заявление на увольнение по собственному желанию',
                  ),
                  const AppleMenuItem(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    iconColor: CupertinoColors.systemGreen,
                    title: 'Перевод на другую должность',
                    subtitle: 'Заявление на перевод на другую должность',
                  ),
                  const AppleMenuItem(
                    icon: CupertinoIcons.money_dollar,
                    iconColor: CupertinoColors.systemOrange,
                    title: 'Материальная помощь',
                    subtitle: 'Заявление на получение материальной помощи',
                  ),
                  const AppleMenuItem(
                    icon: CupertinoIcons.airplane,
                    iconColor: CupertinoColors.systemTeal,
                    title: 'Командировка',
                    subtitle: 'Заявление на служебную командировку',
                  ),
                  const AppleMenuItem(
                    icon: CupertinoIcons.clock,
                    iconColor: CupertinoColors.systemIndigo,
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
                            CupertinoIcons.info,
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
      ),
    );
  }

  /// Показывает форму заявления об отпуске в bottom sheet
  void _showVacationForm(BuildContext context, Profile? profile) {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить данные профиля')),
      );
      return;
    }

    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Ежегодный отпуск',
            child: VacationForm(profile: profile),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Ежегодный отпуск',
          child: VacationForm(profile: profile),
        ),
      );
    }
  }

  /// Показывает форму заявления на отпуск без сохранения заработной платы в bottom sheet
  void _showUnpaidLeaveForm(BuildContext context, Profile? profile) {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить данные профиля')),
      );
      return;
    }

    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Отпуск за свой счёт',
            child: UnpaidLeaveForm(profile: profile),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Отпуск за свой счёт',
          child: UnpaidLeaveForm(profile: profile),
        ),
      );
    }
  }
}
