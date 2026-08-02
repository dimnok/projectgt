import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_assignment.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';

/// Экран «Выданное имущество» с данными из модуля ТМЦ.
class PropertyScreen extends ConsumerWidget {
  /// Создаёт экран выданного имущества.
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProfileProvider).profile;
    final employeeId = profile?.object?['employee_id'] as String?;
    final assignmentsAsync = employeeId == null
        ? const AsyncValue<List<TmcAssignment>>.data([])
        : ref.watch(tmcAssignmentsProvider(employeeId));

    final activeAssignments = assignmentsAsync.maybeWhen(
      data: (list) => list.where((a) => a.isActive).toList(),
      orElse: () => <TmcAssignment>[],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppBarWidget(
        title: 'Выданное имущество',
        leading: BackButton(),
      ),
      body: ContentConstrainedBox(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Имущество, числящееся за вами. При увольнении необходимо сдать.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (employeeId == null)
                _EmptyLinkedEmployee(theme: theme)
              else
                assignmentsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(e.toString()),
                  ),
                  data: (_) {
                    if (activeAssignments.isEmpty) {
                      return _EmptyAssignments(theme: theme);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 12),
                          child: Text(
                            'ВЫДАННОЕ ИМУЩЕСТВО',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        AppleMenuGroup(
                          children: activeAssignments
                              .map(
                                (a) => AppleMenuItem(
                                  icon: CupertinoIcons.cube_box,
                                  iconColor: CupertinoColors.systemBlue,
                                  title: a.itemName ?? 'ТМЦ',
                                  subtitle: _assignmentSubtitle(a),
                                  onTap: () => _showAssignmentDetails(
                                    context: context,
                                    assignment: a,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Если вы обнаружили расхождение в списке имущества, обратитесь к материально ответственному лицу.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _assignmentSubtitle(TmcAssignment assignment) {
    final parts = <String>[];
    if (assignment.inventoryNumber != null) {
      parts.add('инв. № ${assignment.inventoryNumber}');
    }
    parts.add('выдано: ${formatRuDate(assignment.issuedAt)}');
    if (assignment.objectName != null) {
      parts.add(assignment.objectName!);
    }
    return parts.join(' · ');
  }

  void _showAssignmentDetails({
    required BuildContext context,
    required TmcAssignment assignment,
  }) {
    final theme = Theme.of(context);
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(assignment.itemName ?? 'ТМЦ', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (assignment.inventoryNumber != null)
          Text('Инв. № ${assignment.inventoryNumber}'),
        Text('Выдано: ${formatRuDate(assignment.issuedAt)}'),
        if (assignment.plannedReturnDate != null)
          Text(
            'План возврата: ${formatRuDate(assignment.plannedReturnDate!)}',
          ),
        if (assignment.objectName != null) Text('Объект: ${assignment.objectName}'),
        if (assignment.comment != null) Text(assignment.comment!),
      ],
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Выданное имущество',
            footer: GTPrimaryButton(
              text: 'Закрыть',
              onPressed: () => Navigator.of(context).pop(),
            ),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 640),
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: assignment.itemName ?? 'ТМЦ',
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: content,
        ),
      );
    }
  }
}

class _EmptyLinkedEmployee extends StatelessWidget {
  final ThemeData theme;

  const _EmptyLinkedEmployee({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.person_crop_circle_badge_xmark,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Профиль не связан с сотрудником',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  final ThemeData theme;

  const _EmptyAssignments({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.cube_box,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Список пуст',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
