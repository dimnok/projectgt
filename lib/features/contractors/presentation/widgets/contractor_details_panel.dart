import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'contractor_list_shared.dart';

/// Панель детальной информации о контрагенте.
///
/// Отображает все юридические, контактные и финансовые данные контрагента,
/// включая список его банковских счетов. Предоставляет функции редактирования и удаления.
class ContractorDetailsPanel extends ConsumerWidget {
  /// Данные контрагента для отображения.
  final Contractor contractor;

  /// Колбэк для перехода в режим редактирования контрагента.
  final VoidCallback onEdit;

  /// Создает панель деталей контрагента.
  const ContractorDetailsPanel({
    super.key,
    required this.contractor,
    required this.onEdit,
  });

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ContractorDialogs.showConfirmDelete(
      context: context,
      title: 'Удалить контрагента?',
      message: 'Вы уверены, что хотите удалить "${contractor.shortName}"?',
    );

    if (confirmed == true) {
      try {
        await ref
            .read(contractorNotifierProvider.notifier)
            .deleteContractor(contractor.id);
        if (!context.mounted) return;
        SnackBarUtils.showSuccess(context, 'Контрагент удалён');
      } catch (e) {
        if (!context.mounted) return;
        SnackBarUtils.showError(context, 'Ошибка удаления: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ContractorAvatar(contractor: contractor, radius: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contractor.shortName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contractor.fullName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppBadge(
                            text: contractor.type.label,
                            color: ContractorHelper.typeColor(contractor.type),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  PermissionGuard(
                    module: 'contractors',
                    permission: 'update',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onEdit,
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 22,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'contractors',
                    permission: 'delete',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _handleDelete(context, ref),
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 22,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ContractorDetailsSections(
              contractor: contractor,
              labelWidth: 200,
            ),
          ),
        ),
      ],
    );
  }
}
