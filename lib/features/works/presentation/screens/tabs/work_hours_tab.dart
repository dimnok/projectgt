import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../presentation/providers/work_hours_provider.dart'
    as local_hours_provider;
import '../../screens/../providers/work_hours_provider.dart'
    as hours_provider; // fallback import path for monorepo structure
import '../../screens/../providers/work_provider.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
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

  // Идентфикаторы, для которых идёт предзагрузка имени
  final Set<String> _prefetchingEmployeeIds = {};

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

  // Предзагрузка имён сотрудников для снижения дёрганья при прокрутке
  Future<void> _prefetchEmployeeNames(
      List<WorkHour> hours, WidgetRef ref) async {
    bool changed = false;
    final employeesState = ref.read(employee_state.employeeProvider);

    for (final h in hours) {
      final id = h.employeeId;
      if (_employeeNameCache.containsKey(id) ||
          _prefetchingEmployeeIds.contains(id)) {
        continue;
      }

      // Пробуем взять из уже загруженного списка
      final list = employeesState.employees;
      final has = list.where((e) => e.id == id).toList();
      if (has.isNotEmpty) {
        final e = has.first;
        final name =
            '${e.lastName} ${e.firstName}${e.middleName != null && e.middleName!.isNotEmpty ? ' ${e.middleName}' : ''}';
        _employeeNameCache[id] = name;
        changed = true;
        continue;
      }

      // Иначе асинхронно подтянем из репозитория
      _prefetchingEmployeeIds.add(id);
      try {
        await ref
            .read(employee_state.employeeProvider.notifier)
            .getEmployee(id);
        final updated = ref
            .read(employee_state.employeeProvider)
            .employees
            .where((e) => e.id == id)
            .toList();
        if (updated.isNotEmpty) {
          final e = updated.first;
          final name =
              '${e.lastName} ${e.firstName}${e.middleName != null && e.middleName!.isNotEmpty ? ' ${e.middleName}' : ''}';
          _employeeNameCache[id] = name;
          changed = true;
        }
      } catch (_) {
      } finally {
        _prefetchingEmployeeIds.remove(id);
      }
    }

    if (changed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
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
    
    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('works', 'update');
    final bool canModify = !isWorkClosed && canUpdate;

    return Stack(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final hoursAsync = ref.watch(_hoursProvider(widget.workId));
            return hoursAsync.when(
              data: (hours) {
                // Предзагружаем имена — один раз на пришедший набор
                _prefetchEmployeeNames(hours, ref);
                return hours.isEmpty
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
                          final employeeName =
                              _employeeNameCache[hour.employeeId] ??
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
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9.,]')),
                                          ],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
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
                                        padding: const EdgeInsets.only(top: 4),
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
              loading: () => const Center(child: CupertinoActivityIndicator()),
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

  // Удалено: синхронный вывод имён заменён локальным кэшем с предзагрузкой

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
