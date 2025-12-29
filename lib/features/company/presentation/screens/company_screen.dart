import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/company/presentation/widgets/company_info_widgets.dart';
import 'package:projectgt/features/company/presentation/widgets/company_profile_edit_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_bank_account_edit_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_document_edit_dialog.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Экран модуля "Компания".
///
/// Отображает детальную информацию об организации, реквизиты и документы в современном стиле.
class CompanyScreen extends ConsumerWidget {
  /// Создаёт экран "Компания".
  const CompanyScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showBankAccountsDialog(BuildContext context, WidgetRef ref,
      List<CompanyBankAccount> accounts, String companyId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: DesktopDialogContent(
          title: 'Банковские реквизиты',
          child: Column(
            children: [
              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Счета не найдены'),
                )
              else
                ...accounts.map((account) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CompanyInfoRow(
                        label: account.bankName,
                        value: [
                          if (account.bankCity != null &&
                              account.bankCity!.isNotEmpty)
                            'г. ${account.bankCity}',
                          'Р/с: ${account.accountNumber}',
                          if (account.corrAccount != null &&
                              account.corrAccount!.isNotEmpty)
                            'К/с: ${account.corrAccount}',
                          'БИК: ${account.bik ?? '—'}',
                        ].join('\n'),
                        icon: account.isPrimary ? CupertinoIcons.star : null,
                        canCopy: true,
                        onEdit: () {
                          Navigator.pop(context);
                          CompanyBankAccountEditDialog.show(context, companyId,
                              account: account);
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: DesktopDialogContent(
                                title: 'Удаление счета',
                                width: 400,
                                footer: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GTSecondaryButton(
                                      text: 'Отмена',
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    const SizedBox(width: 12),
                                    GTPrimaryButton(
                                      text: 'Удалить',
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Вы уверены, что хотите удалить банковский счет "${account.bankName}"?',
                                ),
                              ),
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await ref
                                  .read(companyRepositoryProvider)
                                  .deleteBankAccount(account.id);
                              ref.invalidate(companyBankAccountsProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                                AppSnackBar.show(
                                  context: context,
                                  message: 'Счет успешно удален',
                                  kind: AppSnackBarKind.success,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context: context,
                                  message: 'Ошибка при удалении: $e',
                                  kind: AppSnackBarKind.error,
                                );
                              }
                            }
                          }
                        },
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentsDialog(BuildContext context, WidgetRef ref,
      List<CompanyDocument> docs, String companyId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: DesktopDialogContent(
          title: 'Лицензии и СРО',
          child: Column(
            children: [
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Документы не найдены'),
                )
              else
                ...docs.map((doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CompanyInfoRow(
                        label: doc.title,
                        value:
                            '${doc.number ?? ''} ${doc.issueDate != null ? "от ${DateFormat('dd.MM.yyyy').format(doc.issueDate!)}" : ""}',
                        onEdit: () {
                          Navigator.pop(context);
                          CompanyDocumentEditDialog.show(context, companyId,
                              document: doc);
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: DesktopDialogContent(
                                title: 'Удаление документа',
                                width: 400,
                                footer: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GTSecondaryButton(
                                      text: 'Отмена',
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    const SizedBox(width: 12),
                                    GTPrimaryButton(
                                      text: 'Удалить',
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Вы уверены, что хотите удалить документ "${doc.title}"?',
                                ),
                              ),
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await ref
                                  .read(companyRepositoryProvider)
                                  .deleteDocument(doc.id);
                              ref.invalidate(companyDocumentsProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                                AppSnackBar.show(
                                  context: context,
                                  message: 'Документ успешно удален',
                                  kind: AppSnackBarKind.success,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context: context,
                                  message: 'Ошибка при удалении: $e',
                                  kind: AppSnackBarKind.error,
                                );
                              }
                            }
                          }
                        },
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileProvider);
    final bankAccountsAsync = ref.watch(companyBankAccountsProvider);
    final documentsAsync = ref.watch(companyDocumentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.98),
      appBar: const AppBarWidget(title: 'О компании'),
      drawer: const AppDrawer(activeRoute: AppRoute.company),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Данные о компании не найдены'));
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Хедер секция
                _CompanyHeaderSection(profile: profile),
                const SizedBox(height: 32),

                // 2. Основной ряд: Организация и Юридические данные (60/40)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Организация и руководство (60%)
                      Expanded(
                        flex: 6,
                        child: CompanyInfoCard(
                          title: 'Организация и руководство',
                          icon: CupertinoIcons.info_circle,
                          children: [
                            CompanyInfoRow(
                              label: 'Полное название',
                              value: profile.nameFull,
                              icon: CupertinoIcons.briefcase,
                            ),
                            CompanyInfoRow(
                              label: 'Сфера деятельности',
                              value: profile.activityDescription ?? '—',
                              icon: CupertinoIcons.briefcase,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Сайт',
                                    value: profile.website ?? '—',
                                    icon: CupertinoIcons.globe,
                                    onAction: profile.website != null
                                        ? () => _launchUrl(profile.website!)
                                        : null,
                                    actionIcon:
                                        CupertinoIcons.arrow_up_right_circle,
                                  ),
                                ),
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'E-mail',
                                    value: profile.email ?? '—',
                                    icon: CupertinoIcons.mail,
                                    onAction: profile.email != null
                                        ? () => _launchUrl(
                                            'mailto:${profile.email}')
                                        : null,
                                    actionIcon: CupertinoIcons.mail,
                                  ),
                                ),
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Телефон компании',
                                    value: profile.phone ?? '—',
                                    icon: CupertinoIcons.phone,
                                    onAction: profile.phone != null
                                        ? () =>
                                            _launchUrl('tel:${profile.phone}')
                                        : null,
                                    actionIcon: CupertinoIcons.phone,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Генеральный директор',
                                    value: profile.directorName ?? '—',
                                    icon: CupertinoIcons.person,
                                  ),
                                ),
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Действует на основании',
                                    value: profile.directorBasis ?? '—',
                                    icon: CupertinoIcons.doc_plaintext,
                                  ),
                                ),
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Телефон директора',
                                    value: profile.directorPhone ?? '—',
                                    icon: profile.directorPhone != null
                                        ? CupertinoIcons.phone
                                        : null,
                                    canCopy: profile.directorPhone != null,
                                    onAction: profile.directorPhone != null
                                        ? () => _launchUrl(
                                            'tel:${profile.directorPhone}')
                                        : null,
                                    actionIcon: CupertinoIcons.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Главный бухгалтер',
                                    value: profile.chiefAccountantName ?? '—',
                                    icon: CupertinoIcons.person_crop_circle,
                                  ),
                                ),
                                const Expanded(child: SizedBox.shrink()),
                                Expanded(
                                  child: CompanyInfoRow(
                                    label: 'Телефон бухгалтера',
                                    value: profile.chiefAccountantPhone ?? '—',
                                    icon: profile.chiefAccountantPhone != null
                                        ? CupertinoIcons.phone
                                        : null,
                                    canCopy:
                                        profile.chiefAccountantPhone != null,
                                    onAction: profile.chiefAccountantPhone !=
                                            null
                                        ? () => _launchUrl(
                                            'tel:${profile.chiefAccountantPhone}')
                                        : null,
                                    actionIcon: CupertinoIcons.phone,
                                    isLast: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Юридические данные (40%)
                      Expanded(
                        flex: 4,
                        child: CompanyInfoCard(
                          title: 'Юридические данные',
                          icon: CupertinoIcons.doc_text,
                          accentColor: Colors.orange,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: CompanyInfoRow(
                                        label: 'ИНН',
                                        value: profile.inn ?? '—',
                                        canCopy: true)),
                                Expanded(
                                    child: CompanyInfoRow(
                                        label: 'КПП',
                                        value: profile.kpp ?? '—',
                                        canCopy: true)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: CompanyInfoRow(
                                        label: 'ОГРН',
                                        value: profile.ogrn ?? '—',
                                        canCopy: true)),
                                Expanded(
                                    child: CompanyInfoRow(
                                        label: 'ОКПО',
                                        value: profile.okpo ?? '—',
                                        canCopy: true)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            CompanyInfoRow(
                              label: 'Система налогообложения',
                              value: profile.taxationSystem ?? '—',
                            ),
                            CompanyInfoRow(
                              label: 'Статус НДС',
                              value: profile.isVatPayer
                                  ? 'Плательщик НДС (${profile.vatRate}%)'
                                  : 'Не является плательщиком НДС',
                            ),
                            CompanyInfoRow(
                                label: 'Юридический адрес',
                                value: profile.legalAddress ?? '—',
                                icon: CupertinoIcons.location),
                            CompanyInfoRow(
                                label: 'Фактический адрес',
                                value: profile.actualAddress ?? '—',
                                icon: CupertinoIcons.location_north,
                                isLast: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 32),

                // 3. Нижний ряд: Банковские счета и Лицензии (50/50)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Банковские счета
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Банковские реквизиты',
                            icon: CupertinoIcons.creditcard,
                            onAdd: () => CompanyBankAccountEditDialog.show(
                                context, profile.id),
                          ),
                          bankAccountsAsync.when(
                            data: (accounts) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (accounts.isEmpty)
                                  const Text('Нет добавленных счетов',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic))
                                else
                                  ...accounts.map((account) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: _InfoQuickButton(
                                          label: account.bankName,
                                          icon: account.isPrimary
                                              ? CupertinoIcons.star_fill
                                              : CupertinoIcons.creditcard,
                                          color: Colors.green,
                                          onTap: () => _showBankAccountsDialog(
                                              context,
                                              ref,
                                              accounts,
                                              profile.id),
                                        ),
                                      )),
                              ],
                            ),
                            loading: () => const CupertinoActivityIndicator(),
                            error: (e, st) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Лицензии и СРО
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Лицензии и СРО',
                            icon: CupertinoIcons.folder,
                            onAdd: () => CompanyDocumentEditDialog.show(
                                context, profile.id),
                          ),
                          documentsAsync.when(
                            data: (docs) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (docs.isEmpty)
                                  const Text('Нет добавленных документов',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic))
                                else
                                  ...docs.map((doc) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: _InfoQuickButton(
                                          label: doc.title,
                                          icon: CupertinoIcons.doc_text,
                                          color: Colors.purple,
                                          onTap: () => _showDocumentsDialog(
                                              context, ref, docs, profile.id),
                                        ),
                                      )),
                              ],
                            ),
                            loading: () => const CupertinoActivityIndicator(),
                            error: (e, st) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, st) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onAdd;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(CupertinoIcons.plus_circle, size: 20),
              color: theme.colorScheme.primary,
              tooltip: 'Добавить',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoQuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _InfoQuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: baseColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: baseColor),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: baseColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyHeaderSection extends StatelessWidget {
  final CompanyProfile profile;
  const _CompanyHeaderSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.15),
                theme.colorScheme.primary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: profile.logoUrl != null && profile.logoUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(profile.logoUrl!,
                              fit: BoxFit.cover))
                      : Icon(
                          CupertinoIcons.building_2_fill,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.nameShort,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              CompanyProfileEditDialog.show(context, profile),
                          icon: const Icon(CupertinoIcons.pencil_circle),
                          color: theme.colorScheme.primary,
                          iconSize: 28,
                          tooltip: 'Редактировать профиль',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ID: ${profile.id.substring(0, 8).toUpperCase()}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
