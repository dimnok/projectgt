import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work.dart';
import '../providers/work_provider.dart';
import '../providers/month_groups_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'work_details_panel.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import '../providers/repositories_providers.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Экран деталей смены с вкладками работ, материалов и часов.
///
/// Используется для отображения детальной информации о смене,
/// а также для управления списками работ, материалов и часов.
class WorkDetailsScreen extends ConsumerStatefulWidget {
  /// Идентификатор смены для отображения деталей.
  final String workId;

  /// Начальный индекс таба (опционально).
  final int initialTabIndex;

  /// Создаёт экран деталей смены по [workId].
  const WorkDetailsScreen({
    super.key,
    required this.workId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<WorkDetailsScreen> createState() => _WorkDetailsScreenState();
}

class _WorkDetailsScreenState extends ConsumerState<WorkDetailsScreen> {
  /// Загруженная локально смена (если нет в глобальном стейте)
  Work? _localWork;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Отложенная проверка наличия смены в стейте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadWork();
    });
  }

  /// Проверяет наличие смены в глобальном стейте, если нет - загружает.
  Future<void> _checkAndLoadWork() async {
    // Сначала проверяем в глобальном стейте
    final globalWork = ref.read(workProvider(widget.workId));

    if (globalWork != null) {
      return; // Уже есть, ничего не делаем
    }

    // Если нет, загружаем локально
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
          'WorkDetailsScreen: Loading work ${widget.workId} from repository...');
      final repository = ref.read(workRepositoryProvider);
      final work = await repository.getWork(widget.workId);
      debugPrint('WorkDetailsScreen: Loaded work result: ${work?.id}');

      if (mounted) {
        setState(() {
          _localWork = work;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('WorkDetailsScreen: Error loading work: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Пытаемся получить смену из глобального стейта или локального
    final globalWork = ref.watch(workProvider(widget.workId));
    final work = globalWork ?? _localWork;

    final isMobile = ResponsiveUtils.isDesktop(context) == false;
    final appearance = MobileAtmosphereAppearance.of(context);

    // Состояние загрузки
    if (work == null && _isLoading) {
      return _wrap(
        isMobile: isMobile,
        appearance: appearance,
        scaffold: Scaffold(
          backgroundColor: isMobile
              ? (appearance.isDark
                    ? appearance.atmosphereBase
                    : Colors.transparent)
              : null,
          appBar: isMobile
              ? null
              : const AppBarWidget(title: 'Загрузка...'),
          body: isMobile
              ? _mobileShiftHeaderAndBody(
                  context: context,
                  ref: ref,
                  appearance: appearance,
                  title: 'Загрузка...',
                  work: null,
                  canDelete: false,
                  bodyChild:
                      const Center(child: CupertinoActivityIndicator()),
                )
              : const Center(child: CupertinoActivityIndicator()),
        ),
      );
    }

    // Состояние ошибки
    if (work == null && _error != null) {
      return _wrap(
        isMobile: isMobile,
        appearance: appearance,
        scaffold: Scaffold(
          backgroundColor: isMobile
              ? (appearance.isDark
                    ? appearance.atmosphereBase
                    : Colors.transparent)
              : null,
          appBar: isMobile ? null : const AppBarWidget(title: 'Ошибка'),
          body: isMobile
              ? _mobileShiftHeaderAndBody(
                  context: context,
                  ref: ref,
                  appearance: appearance,
                  title: 'Ошибка',
                  work: null,
                  canDelete: false,
                  bodyChild:
                      Center(child: Text('Ошибка загрузки: $_error')),
                )
              : Center(child: Text('Ошибка загрузки: $_error')),
        ),
      );
    }

    // Состояние "не найдено"
    if (work == null) {
      return _wrap(
        isMobile: isMobile,
        appearance: appearance,
        scaffold: Scaffold(
          backgroundColor: isMobile
              ? (appearance.isDark
                    ? appearance.atmosphereBase
                    : Colors.transparent)
              : null,
          appBar: isMobile ? null : const AppBarWidget(title: 'Смена'),
          body: isMobile
              ? _mobileShiftHeaderAndBody(
                  context: context,
                  ref: ref,
                  appearance: appearance,
                  title: 'Смена',
                  work: null,
                  canDelete: false,
                  bodyChild: const Center(child: Text('Смена не найдена')),
                )
              : const Center(child: Text('Смена не найдена')),
        ),
      );
    }

    // Отрисовка данных
    final permissionService = ref.watch(permissionServiceProvider);
    final hasDeletePermission = permissionService.can('works', 'delete');

    final currentProfile = ref.watch(currentUserProfileProvider).profile;
    final isCompanyOwner = currentProfile?.systemRole == 'owner';

    final isOwner =
        currentProfile != null && work.openedBy == currentProfile.id;
    final isWorkClosed = work.status.toLowerCase() == 'closed';

    final canDelete =
        hasDeletePermission && ((isOwner && !isWorkClosed) || isCompanyOwner);

    final workDetailsPanel = Material(
      type: MaterialType.transparency,
      child: Builder(
        builder: (scaffoldContext) => WorkDetailsPanel(
          workId: widget.workId,
          parentContext: scaffoldContext,
          initialWork: work,
          initialTabIndex: widget.initialTabIndex,
        ),
      ),
    );

    return _wrap(
      isMobile: isMobile,
      appearance: appearance,
      scaffold: Scaffold(
        backgroundColor: isMobile
            ? (appearance.isDark
                  ? appearance.atmosphereBase
                  : Colors.transparent)
            : null,
        appBar: isMobile
            ? null
            : AppBarWidget(
                title: 'Смена: ${formatRuDate(work.date)}',
                actions: [
                  if (canDelete)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _confirmDeleteWork(context, ref, work),
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                ],
                showThemeSwitch: true,
              ),
        drawer: isMobile ? null : const AppDrawer(activeRoute: AppRoute.works),
        body: isMobile
            ? _mobileShiftHeaderAndBody(
                context: context,
                ref: ref,
                appearance: appearance,
                title: 'Смена: ${formatRuDate(work.date)}',
                work: work,
                canDelete: canDelete,
                bodyChild: workDetailsPanel,
              )
            : workDetailsPanel,
      ),
    );
  }

  /// Шапка в стиле списка «Смены» + контент на мобильном (без [AppBar]).
  ///
  /// Повторяет разметку [WorksListMobileScreen]: [MobileAtmosphereBackdrop] под
  /// всей областью [body], затем [SafeArea] с хедером и [Expanded] для контента.
  Widget _mobileShiftHeaderAndBody({
    required BuildContext context,
    required WidgetRef ref,
    required MobileAtmosphereAppearance appearance,
    required String title,
    required Work? work,
    required bool canDelete,
    required Widget bodyChild,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const MobileAtmosphereBackdrop(),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MobileAtmosphereScreenHeader(
                appearance: appearance,
                title: title,
                leading: MobileAtmosphereChromeCircleButton(
                  appearance: appearance,
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
                ),
                trailing: work != null && canDelete
                    ? MobileAtmosphereChromeCircleButton(
                        appearance: appearance,
                        tooltip: 'Удалить смену',
                        icon: CupertinoIcons.delete,
                        iconColor: Colors.red,
                        onTap: () => _confirmDeleteWork(context, ref, work),
                      )
                    : null,
              ),
              Expanded(child: bodyChild),
            ],
          ),
        ),
      ],
    );
  }

  /// Оборачивает [Scaffold] в [AnnotatedRegion] для корректного тонирования
  /// системных баров на мобильном устройстве.
  Widget _wrap({
    required bool isMobile,
    required MobileAtmosphereAppearance appearance,
    required Widget scaffold,
  }) {
    if (!isMobile) return scaffold;
    final isDark = appearance.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: scaffold,
    );
  }

  /// Показывает диалог подтверждения удаления смены.
  void _confirmDeleteWork(BuildContext context, WidgetRef ref, Work work) {
    CupertinoDialogs.showDeleteConfirmDialog(
      context: context,
      title: 'Подтверждение удаления',
      message:
          'Вы действительно хотите удалить смену от ${formatRuDate(work.date)}?\n\nЭто действие удалит все связанные работы и часы сотрудников. Операция необратима.',
      confirmButtonText: 'Удалить',
      onConfirm: () async {
        if (work.id == null) return;

        await ref.read(worksProvider.notifier).deleteWork(work.id!);

        // Обновляем список смен для немедленного отображения изменений
        await ref.read(monthGroupsProvider.notifier).refresh();

        if (context.mounted) {
          context.goNamed('works');
          AppSnackBar.show(
            context: context,
            message: 'Смена успешно удалена',
            kind: AppSnackBarKind.success,
          );
        }
      },
    );
  }
}
