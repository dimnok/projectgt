import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../presentation/providers/work_hours_provider.dart'
    as local_hours_provider;
import '../../screens/../providers/work_hours_provider.dart'
    as hours_provider; // fallback import path for monorepo structure
import '../../screens/../providers/work_provider.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:projectgt/features/works/domain/entities/work_hour.dart';
import 'package:projectgt/core/utils/modal_utils.dart';

/// Вкладка "Сотрудники" для панели деталей смены.
///
/// Отображает список сотрудников с часами, позволяет добавлять/редактировать/удалять
/// записи при наличии прав (только автор открытой смены или админ).
class WorkHoursTab extends ConsumerStatefulWidget {
  /// Идентификатор смены
  final String workId;

  /// Контекст родительского экрана (для корректного отображения модалок)
  final BuildContext parentContext;

  /// Конструктор вкладки «Сотрудники».
  const WorkHoursTab(
      {super.key, required this.workId, required this.parentContext});

  @override
  ConsumerState<WorkHoursTab> createState() => _WorkHoursTabState();
}

class _WorkHoursTabState extends ConsumerState<WorkHoursTab> {
  // Кэш имен сотрудников
  final Map<String, String> _employeeNameCache = {};

  // Режим массового редактирования часов
  bool _isMassEdit = false;

  // Контроллеры ввода часов по id записи
  final Map<String, TextEditingController> _hourControllers = {};

  TextEditingController _ensureHourController(String id, num initialHours) {
    if (_hourControllers[id] == null) {
      _hourControllers[id] =
          TextEditingController(text: initialHours.toString());
    }
    return _hourControllers[id]!;
  }

  @override
  void dispose() {
    for (final c in _hourControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем смену для проверки статуса/прав
    final workAsync = ref.watch(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';
    final currentProfile = ref.watch(profileProvider).profile;
    final isAdmin = ref.watch(authProvider).user?.role == 'admin';
    final bool isOwner = currentProfile != null &&
        workAsync != null &&
        workAsync.openedBy == currentProfile.id;
    final bool canModify = !isWorkClosed && (isOwner || isAdmin);

    return Stack(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final hoursAsync = ref.watch(_hoursProvider(widget.workId));
            return hoursAsync.when(
              data: (hours) => hours.isEmpty
                  ? const Center(
                      child: Text(
                          'Нет сотрудников в смене. Добавьте сотрудника, нажав на "+"'))
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: hours.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, i) {
                        final hour = hours[i];

                        return FutureBuilder<String>(
                          future: _getEmployeeName(hour.employeeId, ref),
                          builder: (context, snapshot) {
                            final employeeName = snapshot.data ??
                                'Сотрудник ID: ${hour.employeeId}';
                            final hoursController =
                                _ensureHourController(hour.id, hour.hours);

                            return Dismissible(
                              key: Key(hour.id),
                              direction: canModify
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.onError,
                                  size: 24,
                                ),
                              ),
                              confirmDismiss: canModify
                                  ? (direction) async {
                                      return await _showDeleteHourConfirmationDialog(
                                          context, hour);
                                    }
                                  : null,
                              onDismissed: canModify
                                  ? (direction) {
                                      ref
                                          .read(_hoursProvider(widget.workId)
                                              .notifier)
                                          .delete(hour.id);
                                    }
                                  : null,
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          employeeName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (_isMassEdit && canModify)
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: hoursController,
                                            textAlign: TextAlign.center,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'[0-9.,]')),
                                            ],
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${hour.hours} ч',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: hour.comment != null &&
                                          hour.comment!.isNotEmpty
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Комментарий: ${hour.comment}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        )
                                      : null,
                                  onTap: canModify
                                      ? () {
                                          ModalUtils.showWorkHourFormModal(
                                            widget.parentContext,
                                            workId: widget.workId,
                                            initial: hour,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Ошибка: $e')),
            );
          },
        ),

        // Кнопка добавления часов - только при праве редактирования
        if (canModify)
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom + 56 + 12,
            child: FloatingActionButton(
              heroTag: 'toggleEditHours',
              mini: true,
              onPressed: () async {
                if (!_isMassEdit) {
                  setState(() {
                    _isMassEdit = true;
                    // Заполнить контроллеры актуальными значениями при входе в режим
                    final current =
                        ref.read(_hoursProvider(widget.workId)).valueOrNull;
                    if (current != null) {
                      for (final h in current) {
                        final controller = _ensureHourController(h.id, h.hours);
                        controller.text = (h.hours == 0 || h.hours == 0.0)
                            ? ''
                            : h.hours.toString();
                      }
                    }
                  });
                } else {
                  // Сохранение всех изменений одним действием
                  final current =
                      ref.read(_hoursProvider(widget.workId)).valueOrNull;
                  if (current != null) {
                    final List<WorkHour> updated = [];
                    for (final h in current) {
                      final controller = _hourControllers[h.id];
                      if (controller == null) continue;
                      final raw = controller.text.replaceAll(',', '.');
                      final parsed = num.tryParse(raw);
                      if (parsed == null) continue;
                      if (parsed != h.hours && parsed >= 0) {
                        updated.add(
                          h.copyWith(hours: parsed, updatedAt: DateTime.now()),
                        );
                      }
                    }
                    if (updated.isNotEmpty) {
                      await ref
                          .read(_hoursProvider(widget.workId).notifier)
                          .updateBulk(updated);
                    }
                  }
                  if (mounted) {
                    setState(() {
                      _isMassEdit = false;
                    });
                  }
                }
              },
              child: Icon(_isMassEdit ? Icons.save : Icons.access_time),
            ),
          ),
        if (canModify)
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: FloatingActionButton(
              heroTag: 'addWorkHour',
              mini: true,
              onPressed: () {
                ModalUtils.showWorkHourFormModal(
                  widget.parentContext,
                  workId: widget.workId,
                );
              },
              child: const Icon(Icons.add),
            ),
          ),

        // Сообщение о закрытой смене
        if (isWorkClosed)
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Смена закрыта',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Провайдер часов — поддержка альтернативного пути импорта
  StateNotifierProviderFamily<dynamic, AsyncValue<List<WorkHour>>, String>
      get _hoursProvider {
    // Пробуем локальный импорт, иначе используем основной
    try {
      return local_hours_provider.workHoursProvider;
    } catch (_) {
      return hours_provider.workHoursProvider;
    }
  }

  // Получает имя сотрудника из кэша или из репозитория
  Future<String> _getEmployeeName(String employeeId, WidgetRef ref) async {
    if (_employeeNameCache.containsKey(employeeId)) {
      return _employeeNameCache[employeeId]!;
    }

    final employees = ref.read(employee_state.employeeProvider).employees;
    final employee = employees.where((e) => e.id == employeeId).toList().isEmpty
        ? null
        : employees.firstWhere((e) => e.id == employeeId);

    if (employee != null) {
      final name =
          '${employee.lastName} ${employee.firstName}${employee.middleName != null && employee.middleName!.isNotEmpty ? ' ${employee.middleName}' : ''}';
      _employeeNameCache[employeeId] = name;
      return name;
    }

    try {
      await ref
          .read(employee_state.employeeProvider.notifier)
          .getEmployee(employeeId);
      final updatedEmployees =
          ref.read(employee_state.employeeProvider).employees;
      final updatedEmployee =
          updatedEmployees.where((e) => e.id == employeeId).toList().isEmpty
              ? null
              : updatedEmployees.firstWhere((e) => e.id == employeeId);

      if (updatedEmployee != null) {
        final name =
            '${updatedEmployee.lastName} ${updatedEmployee.firstName}${updatedEmployee.middleName != null && updatedEmployee.middleName!.isNotEmpty ? ' ${updatedEmployee.middleName}' : ''}';
        _employeeNameCache[employeeId] = name;
        return name;
      }
    } catch (_) {}

    return 'Сотрудник ID: $employeeId';
  }

  /// Подтверждение удаления сотрудника из смены
  Future<bool?> _showDeleteHourConfirmationDialog(
      BuildContext context, WorkHour hour) async {
    return await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => const CupertinoAlertDialog(
        title: Text('Подтверждение'),
        content: Text('Вы действительно хотите удалить сотрудника из смены?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
