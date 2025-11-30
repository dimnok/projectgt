import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/notifications/notification_service.dart';
import 'package:projectgt/features/works/presentation/providers/work_provider.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';

/// Экран настроек уведомлений.
///
/// Позволяет пользователю настроить параметры получения уведомлений
/// о сменах, напоминаниях и других событиях приложения.
class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  /// Создает экран настроек уведомлений.
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  // Флаги включения отдельных слотов
  bool _slot1Enabled = true;
  bool _slot2Enabled = true;
  bool _slot3Enabled = true;

  // Текущее значение слотов в формате HH:mm
  late String _slot1;
  late String _slot2;
  late String _slot3;
  bool _enabled = true;

  List<String> get _timeOptions {
    final List<String> res = [];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 30) {
        final hh = h.toString().padLeft(2, '0');
        final mm = m.toString().padLeft(2, '0');
        res.add('$hh:$mm');
      }
    }
    return res;
  }

  List<String> _optionsWithCurrent(String value) {
    final opts = _timeOptions;
    if (!opts.contains(value)) {
      return [value, ...opts];
    }
    return opts;
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).profile;
    // Читаем сохранённый флаг включения уведомлений; если отсутствует —
    // включено тогда, когда есть slot_times
    final slotTimes =
        (profile?.object != null && profile!.object!.containsKey('slot_times'))
            ? (profile.object!['slot_times'] as List?)?.cast<String>()
            : null;
    final bool? savedEnabled = (profile?.object != null &&
            profile!.object!.containsKey('notifications_enabled'))
        ? profile.object!['notifications_enabled'] as bool?
        : null;
    _enabled = savedEnabled ?? (slotTimes != null && slotTimes.isNotEmpty);
    _slot1Enabled = slotTimes != null && slotTimes.isNotEmpty;
    _slot2Enabled = slotTimes != null && slotTimes.length > 1;
    _slot3Enabled = slotTimes != null && slotTimes.length > 2;
    _slot1 =
        (slotTimes != null && slotTimes.isNotEmpty) ? slotTimes[0] : '13:00';
    _slot2 =
        (slotTimes != null && slotTimes.length > 1) ? slotTimes[1] : '15:00';
    _slot3 =
        (slotTimes != null && slotTimes.length > 2) ? slotTimes[2] : '18:00';
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildSwitch(
      {required bool value, required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    final color =
        value ? CupertinoColors.activeGreen : CupertinoColors.systemGrey;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: color,
      borderRadius: BorderRadius.circular(16),
      // minSize удален, т.к. он deprecated и его функционал заменяется внутренними отступами (padding)
      onPressed: () => onChanged(!value),
      child: Text(
        value ? 'ВКЛ' : 'ВЫКЛ',
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _hasAtLeastOneSlotEnabled() =>
      _slot1Enabled || _slot2Enabled || _slot3Enabled;

  Future<void> _save() async {
    if (!_enabled) {
      // Выключено — удаляем slot_times и отменяем напоминания для открытых смен сразу
      final notifier = ref.read(currentUserProfileProvider.notifier);
      final profile = ref.read(currentUserProfileProvider).profile;
      if (profile == null) return;
      final nextObject = {...(profile.object ?? <String, dynamic>{})};
      // Пишем пустой массив, чтобы в БД колонка slot_times была очищена
      nextObject['slot_times'] = <String>[];
      nextObject['notifications_enabled'] = false;
      final updated =
          profile.copyWith(object: nextObject, updatedAt: DateTime.now());
      await notifier.updateCurrentUserProfile(updated);
      setState(() {
        _enabled = false;
        _slot1Enabled = false;
        _slot2Enabled = false;
        _slot3Enabled = false;
      });

      // Обновляем напоминания немедленно: отменяем для всех открытых смен пользователя на сегодня
      await ref.read(worksProvider.notifier).loadWorks();
      final worksState = ref.read(worksProvider);
      final today = DateTime.now();
      final dayStart = DateTime(today.year, today.month, today.day);
      final service = ref.read(notificationServiceProvider);
      for (final w in worksState.works) {
        if (w.openedBy == profile.id &&
            w.status.toLowerCase() == 'open' &&
            DateTime(w.date.year, w.date.month, w.date.day)
                .isAtSameMomentAs(dayStart) &&
            w.id != null) {
          await service.cancelShiftReminders(w.id!);
        }
      }

      if (mounted) Navigator.pop(context);
      return;
    }

    if (!_hasAtLeastOneSlotEnabled()) {
      SnackBarUtils.showWarning(
          context, 'Включите хотя бы один слот напоминаний');
      return;
    }
    final notifier = ref.read(currentUserProfileProvider.notifier);
    final profile = ref.read(currentUserProfileProvider).profile;
    if (profile == null) return;

    final nextObject = {...(profile.object ?? <String, dynamic>{})};
    final List<String> times = [];
    if (_slot1Enabled) times.add(_slot1);
    if (_slot2Enabled) times.add(_slot2);
    if (_slot3Enabled) times.add(_slot3);
    nextObject['slot_times'] = times;
    nextObject['notifications_enabled'] = true;

    final updated =
        profile.copyWith(object: nextObject, updatedAt: DateTime.now());
    await notifier.updateCurrentUserProfile(updated);
    // Профиль в провайдере уже обновлён; локальное состояние актуально

    // Немедленно пересоздаём напоминания для открытых смен пользователя на сегодня
    await ref.read(worksProvider.notifier).loadWorks();
    final worksState = ref.read(worksProvider);
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final service = ref.read(notificationServiceProvider);

    for (final w in worksState.works) {
      if (w.openedBy == profile.id &&
          w.status.toLowerCase() == 'open' &&
          DateTime(w.date.year, w.date.month, w.date.day)
              .isAtSameMomentAs(dayStart) &&
          w.id != null) {
        await service.cancelShiftReminders(w.id!);
        await service.scheduleShiftReminders(
          shiftId: w.id!,
          date: DateTime.now(),
          slotTimesHHmm: times,
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const AppBarWidget(
          title: 'Настройки уведомлений',
          showThemeSwitch: false,
          centerTitle: true,
          leading: BackButton()),
      body: ContentConstrainedBox(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.bell_fill),
                  title: const Text('Включить напоминания о сменах'),
                  subtitle:
                      const Text('Если выключено — напоминания не приходят'),
                  trailing: _buildSwitch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ),
                if (_enabled) ...[
                  const SizedBox(height: 16),
                  Text('Время напоминаний', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  _buildSlotRow(
                    context: context,
                    label: 'Уведомление 1',
                    value: _slot1,
                    enabled: _slot1Enabled,
                    onToggle: (v) => setState(() => _slot1Enabled = v),
                    onChanged: (v) => setState(() => _slot1 = v ?? _slot1),
                  ),
                  const SizedBox(height: 12),
                  _buildSlotRow(
                    context: context,
                    label: 'Уведомление 2',
                    value: _slot2,
                    enabled: _slot2Enabled,
                    onToggle: (v) => setState(() => _slot2Enabled = v),
                    onChanged: (v) => setState(() => _slot2 = v ?? _slot2),
                  ),
                  const SizedBox(height: 12),
                  _buildSlotRow(
                    context: context,
                    label: 'Уведомление 3',
                    value: _slot3,
                    enabled: _slot3Enabled,
                    onToggle: (v) => setState(() => _slot3Enabled = v),
                    onChanged: (v) => setState(() => _slot3 = v ?? _slot3),
                  ),
                ],
                const SizedBox(height: 24),
                GTPrimaryButton(
                  text: 'Сохранить',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotRow({
    required BuildContext context,
    required String label,
    required String value,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        _buildSwitch(
          value: enabled,
          onChanged: onToggle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Opacity(
            opacity: enabled ? 1.0 : 0.6,
            child: AbsorbPointer(
              absorbing: !enabled,
              child: GTStringDropdown(
                items: _optionsWithCurrent(value),
                selectedItem: value,
                onSelectionChanged: onChanged,
                labelText: label,
                hintText: 'Выберите время',
                allowCustomInput: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
