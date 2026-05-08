import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/features/works/presentation/widgets/month_details_panel.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import '../../data/models/month_group.dart';

/// Мобильный экран со статистикой месяца.
///
/// При долгом нажатии на заголовок месяца в списке смен открывается этот экран.
/// Он инициирует загрузку смен месяца через `monthGroupsProvider` и отображает
/// те же агрегаты, что и десктопная панель `MonthDetailsPanel`.
class MonthDetailsMobileScreen extends ConsumerStatefulWidget {
  /// Группа месяца, по которой требуется показать статистику.
  final MonthGroup initialGroup;

  /// Создаёт мобильный экран со статистикой месяца.
  const MonthDetailsMobileScreen({
    super.key,
    required this.initialGroup,
  });

  @override
  ConsumerState<MonthDetailsMobileScreen> createState() =>
      _MonthDetailsMobileScreenState();
}

class _MonthDetailsMobileScreenState
    extends ConsumerState<MonthDetailsMobileScreen> {
  MonthGroup? _resolvedGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(monthGroupsProvider.notifier)
          .expandMonth(widget.initialGroup.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthGroupsAsync = ref.watch(monthGroupsProvider);

    final currentGroup = monthGroupsAsync.maybeWhen(
      data: (groups) => groups.firstWhere(
        (group) => group.month == widget.initialGroup.month,
        orElse: () => _resolvedGroup ?? widget.initialGroup,
      ),
      orElse: () => _resolvedGroup ?? widget.initialGroup,
    );

    _resolvedGroup = currentGroup;

    final formattedMonth = DateFormat('LLLL yyyy', 'ru_RU')
        .format(currentGroup.month)
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');

    final appearance = MobileAtmosphereAppearance.of(context);
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
      child: Scaffold(
        appBar: AppBarWidget(
          title: formattedMonth,
          leading: const BackButton(),
          centerTitle: true,
          showThemeSwitch: false,
        ),
        backgroundColor:
            isDark ? appearance.atmosphereBase : Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            MonthDetailsPanel(
              group: currentGroup,
              showMobileAppBar: false,
              useGroupedBackground: false,
            ),
          ],
        ),
      ),
    );
  }
}
