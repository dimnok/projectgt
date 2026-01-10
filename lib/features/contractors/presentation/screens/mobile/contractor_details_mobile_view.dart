import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import '../../widgets/contractor_list_shared.dart';
import '../contractor_form_screen.dart';

/// Мобильное представление деталей контрагента.
///
/// Отображает всю информацию о контрагенте в виде вертикального списка разделов.
class ContractorDetailsMobileView extends ConsumerWidget {
  /// Данные контрагента.
  final Contractor contractor;

  /// Показывать ли AppBar.
  final bool showAppBar;

  /// Создает мобильное представление деталей контрагента.
  const ContractorDetailsMobileView({
    super.key,
    required this.contractor,
    this.showAppBar = true,
  });

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ContractorDialogs.showConfirmDelete(
      context: context,
      title: 'Удалить контрагента?',
      message: 'Вы уверены, что хотите удалить этого контрагента?',
    );

    if (confirmed == true) {
      try {
        await ref
            .read(contractorNotifierProvider.notifier)
            .deleteContractor(contractor.id);
        if (context.mounted) {
          context.goNamed('contractors');
          SnackBarUtils.showSuccess(context, 'Контрагент удалён');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Ошибка удаления: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: showAppBar
          ? AppBarWidget(
              title: contractor.shortName,
              leading: const BackButton(),
              actions: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          ContractorFormScreen(contractorId: contractor.id),
                    );
                  },
                  child: const Icon(
                    CupertinoIcons.pencil,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _handleDelete(context, ref),
                  child: Icon(
                    CupertinoIcons.trash,
                    color: theme.colorScheme.error,
                    size: 22,
                  ),
                ),
              ],
              showThemeSwitch: false,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Center(
              child: Column(
                children: [
                  ContractorAvatar(
                    contractor: contractor,
                    radius: 50,
                    useHero: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contractor.shortName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (contractor.fullName.length < 60 &&
                      contractor.fullName != contractor.shortName) ...[
                    const SizedBox(height: 8),
                    Text(
                      contractor.fullName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppBadge(
                    text: contractor.type.label,
                    color: ContractorHelper.typeColor(contractor.type),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ContractorDetailsSections(contractor: contractor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
