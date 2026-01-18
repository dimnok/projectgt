import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/company/presentation/widgets/company_create_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_join_dialog.dart';

/// Диалог выбора способа добавления компании (создание или вступление).
class CompanyAddSelectionDialog extends StatelessWidget {
  /// Создаёт экземпляр [CompanyAddSelectionDialog].
  const CompanyAddSelectionDialog({super.key});

  /// Показывает диалог выбора.
  static Future<void> show(BuildContext context) async {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: CompanyAddSelectionDialog(),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const CompanyAddSelectionDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SelectionItem(
          title: 'Создать новую',
          subtitle: 'Зарегистрируйте свою организацию и начните управлять процессами',
          icon: CupertinoIcons.add_circled,
          onTap: () {
            Navigator.pop(context);
            CompanyCreateDialog.show(context);
          },
        ),
        const SizedBox(height: 12),
        _SelectionItem(
          title: 'Вступить по коду',
          subtitle: 'Присоединитесь к существующей компании по коду приглашения',
          icon: CupertinoIcons.ticket,
          onTap: () {
            Navigator.pop(context);
            CompanyJoinDialog.show(context);
          },
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Добавить компанию',
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: 'Добавить компанию',
      child: content,
    );
  }
}

class _SelectionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
          color: isDark 
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
