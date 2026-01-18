import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/company/presentation/widgets/company_profile_edit_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_bank_account_edit_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_document_edit_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_info_widgets.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/ui_utils.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Мобильная версия экрана "О компании" в стиле iOS.
///
/// Отображает полную информацию об организации, контактные данные,
/// банковские реквизиты и документы. Использует сложные анимации
/// в заголовке для создания бесшовного пользовательского опыта.
class CompanyScreenMobile extends ConsumerWidget {
  /// Создаёт мобильную версию экрана "О компании".
  const CompanyScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileProvider);
    final bankAccountsAsync = ref.watch(companyBankAccountsProvider);
    final documentsAsync = ref.watch(companyDocumentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('company_scaffold'),
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(activeRoute: AppRoute.company),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Данные не найдены'));
          }
          return Builder(
            builder: (context) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CompanyHeaderDelegate(
                      topPadding: MediaQuery.of(context).padding.top,
                      profile: profile,
                      onMenuTap: () => Scaffold.of(context).openDrawer(),
                      onEditTap: () =>
                          CompanyProfileEditDialog.show(context, profile),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        CompanyInfoCard(
                          title: 'Организация',
                          icon: CupertinoIcons.info_circle,
                          children: [
                            CompanyInfoRow(
                              label: 'Полное название',
                              value: profile.nameFull,
                            ),
                            CompanyInfoRow(
                              label: 'ИНН',
                              value: profile.inn,
                              canCopy: true,
                            ),
                            CompanyInfoRow(
                              label: 'КПП',
                              value: profile.kpp,
                              canCopy: true,
                            ),
                            CompanyInfoRow(
                              label: 'ОГРН',
                              value: profile.ogrn,
                              canCopy: true,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CompanyInfoCard(
                          title: 'Адреса',
                          icon: CupertinoIcons.location,
                          children: [
                            CompanyInfoRow(
                              label: 'Юридический адрес',
                              value: profile.legalAddress,
                              canCopy: true,
                            ),
                            CompanyInfoRow(
                              label: 'Фактический адрес',
                              value: profile.actualAddress,
                              canCopy: true,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CompanyInfoCard(
                          title: 'Руководство',
                          icon: CupertinoIcons.person_2,
                          children: [
                            CompanyInfoRow(
                              label: 'Директор',
                              value: profile.directorName,
                            ),
                            CompanyInfoRow(
                              label: 'Телефон',
                              value: profile.directorPhone,
                              actionIcon: CupertinoIcons.phone,
                              onAction: () => UIUtils.launchExternalUrl(
                                'tel:${profile.directorPhone}',
                              ),
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CompanyInfoCard(
                          title: 'Контакты',
                          icon: CupertinoIcons.phone,
                          children: [
                            if (profile.website != null)
                              CompanyInfoRow(
                                label: 'Сайт',
                                value: profile.website!,
                                actionIcon: CupertinoIcons.globe,
                                onAction: () =>
                                    UIUtils.launchExternalUrl(profile.website!),
                              ),
                            CompanyInfoRow(
                              label: 'E-mail',
                              value: profile.email,
                              actionIcon: CupertinoIcons.mail,
                              onAction: () => UIUtils.launchExternalUrl(
                                'mailto:${profile.email}',
                              ),
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildListHeader(
                          theme,
                          title: 'Банковские счета',
                          onAdd: () => CompanyBankAccountEditDialog.show(
                            context,
                            profile.id,
                          ),
                        ),
                        if ((bankAccountsAsync.value ?? []).isEmpty)
                          _buildEmptyState(theme)
                        else
                          ...bankAccountsAsync.value!.map(
                            (account) =>
                                _buildAccountItem(context, account, profile.id),
                          ),
                        const SizedBox(height: 24),
                        _buildListHeader(
                          theme,
                          title: 'Лицензии и СРО',
                          onAdd: () => CompanyDocumentEditDialog.show(
                            context,
                            profile.id,
                          ),
                        ),
                        if ((documentsAsync.value ?? []).isEmpty)
                          _buildEmptyState(theme)
                        else
                          ...documentsAsync.value!.map(
                            (doc) =>
                                _buildDocumentItem(context, doc, profile.id),
                          ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, st) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  Widget _buildListHeader(
    ThemeData theme, {
    required String title,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onAdd,
            minimumSize: const Size(0, 0),
            child: Icon(
              CupertinoIcons.plus_circle_fill,
              size: 22,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        'Данные отсутствуют',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    CompanyBankAccount account,
    String companyId,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => CompanyBankAccountEditDialog.show(
          context,
          companyId,
          account: account,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  account.isPrimary
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.creditcard,
                  size: 16,
                  color: account.isPrimary
                      ? Colors.orange
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'р/с ${account.accountNumber}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context,
    CompanyDocument doc,
    String companyId,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            CompanyDocumentEditDialog.show(context, companyId, document: doc),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.doc_text,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.number ?? ''} ${doc.issueDate != null ? "от ${formatRuDate(doc.issueDate!)}" : ""}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final dynamic profile;
  final VoidCallback onMenuTap;
  final VoidCallback onEditTap;

  _CompanyHeaderDelegate({
    required this.topPadding,
    required this.profile,
    required this.onMenuTap,
    required this.onEditTap,
  });

  @override
  double get minExtent => topPadding + 50;
  @override
  double get maxExtent => topPadding + 180;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // 1. Логотип просто исчезает
    final logoOpacity = (1 - progress * 2.5).clamp(0.0, 1.0);

    // 2. Математика для "бесшовного" названия
    final double startTop = topPadding + 40;
    final double endTop = topPadding + 13;

    // Плавно двигаем название снизу (под лого) вверх
    const double titleStartOffset = 82.0;
    const double titleEndOffset = 0.0;
    final double currentTitleTop =
        (startTop + titleStartOffset) -
        (titleStartOffset - titleEndOffset + (startTop - endTop)) * progress;

    // Плавное изменение размера шрифта
    final double currentFontSize = 22 - (22 - 17) * progress;

    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ЛОГОТИП
          Positioned(
            top: startTop,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: logoOpacity,
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: profile.logoUrl != null && profile.logoUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            profile.logoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          CupertinoIcons.building_2_fill,
                          size: 35,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
            ),
          ),

          // НАЗВАНИЕ
          Positioned(
            top: currentTitleTop,
            left: 60,
            right: 60,
            child: Text(
              profile.nameShort ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: currentFontSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // КНОПКИ
          Positioned(
            top: topPadding,
            left: 8,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onMenuTap,
              child: Icon(
                CupertinoIcons.bars,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Positioned(
            top: topPadding,
            right: 8,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onEditTap,
              child: Icon(
                CupertinoIcons.pencil_circle,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CompanyHeaderDelegate oldDelegate) => true;
}
