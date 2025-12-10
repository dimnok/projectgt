import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/procurement/data/models/bot_user_model.dart';
import 'package:projectgt/features/procurement/presentation/controllers/procurement_settings_controller.dart';
import 'package:projectgt/features/procurement/presentation/controllers/procurement_settings_state.dart';
import 'package:projectgt/features/procurement/presentation/widgets/procurement_stage_card.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

/// Панель настроек процесса закупок.
///
/// Позволяет назначать ответственных сотрудников на различные этапы процесса закупки:
/// - Инициаторы (creators)
/// - Технический директор (manager)
/// - Снабжение (warehouse)
/// - Бухгалтерия (accountant)
/// - Директор (director)
class ProcurementSettingsPanel extends ConsumerWidget {
  /// Флаг стилизации в виде панели (с фоном и скруглением).
  final bool styleAsPanel;

  /// Флаг отображения заголовка.
  final bool showTitle;

  /// Создаёт панель настроек закупок.
  const ProcurementSettingsPanel({
    super.key,
    this.styleAsPanel = true,
    this.showTitle = true,
  });

  void _showUserSelector(
    BuildContext context,
    WidgetRef ref,
    List<BotUserModel> users,
    String stage,
    List<String> currentIds,
  ) {
    showDialog(
      context: context,
      builder: (context) => _UserSelectorDialog(
        users: users,
        selectedIds: currentIds,
        onSave: (newIds) {
          ref
              .read(procurementSettingsControllerProvider.notifier)
              .updateStage(stage, newIds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(procurementSettingsControllerProvider);

    Widget content = stateAsync.when(
      data: (state) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (showTitle) ...[
            Text(
              'Настройки процесса закупок',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
          ],
          _buildCard(
              context,
              ref,
              state,
              'creators',
              '1. Инициаторы заявки',
              'Сотрудники, имеющие право создавать новые заявки.',
              CupertinoIcons.person_badge_plus),
          const SizedBox(height: 16),
          _buildCard(
              context,
              ref,
              state,
              'manager',
              '2. Технический директор (Согласование)',
              'Утверждает номенклатуру, проверяет обоснованность.',
              CupertinoIcons.checkmark_shield),
          const SizedBox(height: 16),
          _buildCard(
              context,
              ref,
              state,
              'warehouse',
              '3. Склад (Снабжение)',
              'Формирует заказ, работает с поставщиками, прикрепляет счета.',
              CupertinoIcons.cube_box),
          const SizedBox(height: 16),
          _buildCard(
              context,
              ref,
              state,
              'accountant',
              '4. Бухгалтерия (Оплата)',
              'Проверяет счета и готовит платежи в банк-клиенте.',
              CupertinoIcons.doc_text),
          const SizedBox(height: 16),
          _buildCard(
              context,
              ref,
              state,
              'director',
              '5. Директор (Утверждение)',
              'Финальное подтверждение факта оплаты счета.',
              CupertinoIcons.money_rubl),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Ошибка: $err')),
    );

    if (styleAsPanel) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    ProcurementSettingsState state,
    String stage,
    String title,
    String description,
    IconData icon,
  ) {
    return ProcurementStageCard(
      title: title,
      description: description,
      stage: stage,
      icon: icon,
      selectedIds: state.config[stage] ?? [],
      users: state.users,
      onUpdate: (ids) => ref
          .read(procurementSettingsControllerProvider.notifier)
          .updateStage(stage, ids),
      onAdd: () => _showUserSelector(
          context, ref, state.users, stage, state.config[stage] ?? []),
    );
  }
}

class _UserSelectorDialog extends StatefulWidget {
  final List<BotUserModel> users;
  final List<String> selectedIds;
  final Function(List<String>) onSave;

  const _UserSelectorDialog({
    required this.users,
    required this.selectedIds,
    required this.onSave,
  });

  @override
  State<_UserSelectorDialog> createState() => _UserSelectorDialogState();
}

class _UserSelectorDialogState extends State<_UserSelectorDialog> {
  late List<String> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DesktopDialogContent(
        title: 'Выберите сотрудников',
        padding: EdgeInsets.zero,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: 'Отмена',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              text: 'Сохранить',
              onPressed: () {
                widget.onSave(_tempSelectedIds);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.users.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final isSelected = _tempSelectedIds.contains(user.id);
            return Column(
              children: [
                if (index > 0) const Divider(height: 1),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _tempSelectedIds.remove(user.id);
                      } else {
                        _tempSelectedIds.add(user.id);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              if (user.telegramChatId != 0)
                                Text(
                                  'ID: ${user.telegramChatId}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
