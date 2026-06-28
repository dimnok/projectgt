import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:projectgt/presentation/state/profile_state.dart';
import '../../../presentation/providers/work_hours_provider.dart'
    as local_hours_provider;
import '../../screens/../providers/work_hours_provider.dart'
    as hours_provider; // fallback import path for monorepo structure
import '../../screens/../providers/work_provider.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:projectgt/features/works/domain/entities/work_hour.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/works/presentation/widgets/work_detail_data_spacing.dart';

/// Вкладка "Сотрудники" для панели деталей смены.
///
/// Отображает список сотрудников с часами, позволяет добавлять/редактировать/удалять
/// записи при наличии прав (только автор открытой смены или админ).
class WorkHoursTab extends ConsumerStatefulWidget {
  /// Идентификатор смены
  final String workId;

  /// Контекст родительского экрана (для корректного отображения модалок)
  final BuildContext parentContext;

  /// Предварительно загруженная смена (опционально).
  final Work? initialWork;

  /// Конструктор вкладки «Сотрудники».
  const WorkHoursTab({
    super.key,
    required this.workId,
    required this.parentContext,
    this.initialWork,
  });

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

  /// Выбранный пресет часов для всех сотрудников (8, 10 или 12).
  int? _selectedPresetHours;

  /// Доступные пресеты часов для массового заполнения.
  static const List<int> _presetHoursOptions = [8, 10, 12];

  // Контроллеры ввода часов по id записи
  final Map<String, TextEditingController> _hourControllers = {};

  /// Заполняет поля часов всем сотрудникам выбранным пресетом.
  void _applyPresetHours(int presetHours, List<WorkHour> currentHours) {
    setState(() {
      _isMassEdit = true;
      _selectedPresetHours = presetHours;
      for (final h in currentHours) {
        _ensureHourController(h.id, h.hours).text = presetHours.toString();
      }
    });
  }

  /// Сбрасывает подсветку пресета при ручном изменении часов.
  void _onHourFieldChanged() {
    if (_selectedPresetHours != null) {
      setState(() => _selectedPresetHours = null);
    }
  }

  TextEditingController _ensureHourController(String id, num initialHours) {
    if (_hourControllers[id] == null) {
      _hourControllers[id] = TextEditingController(
        text: initialHours.toString(),
      );
    }
    return _hourControllers[id]!;
  }

  // Предзагрузка имён сотрудников для снижения дёрганья при прокрутке
  Future<void> _prefetchEmployeeNames(
    List<WorkHour> hours,
    WidgetRef ref,
  ) async {
    bool changed = false;
    final employeesState = ref.read(employee_state.employeeProvider);

    // 1) Заполняем кэш из уже загруженных данных
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final existingById = {
      for (final e in employeesState.employees)
        e.id: isDesktop
            ? formatFullName(e.lastName, e.firstName, e.middleName)
            : formatAbbreviatedName(e.lastName, e.firstName, e.middleName),
    };

    final List<String> missingIds = [];
    for (final h in hours) {
      final id = h.employeeId;
      if (_employeeNameCache.containsKey(id) ||
          _prefetchingEmployeeIds.contains(id)) {
        continue;
      }

      final existingName = existingById[id];
      if (existingName != null) {
        _employeeNameCache[id] = existingName;
        changed = true;
        continue;
      }

      missingIds.add(id);
    }

    if (missingIds.isEmpty) {
      if (changed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
      }
      return;
    }

    // 2) Параллельная подгрузка отсутствующих сотрудников
    _prefetchingEmployeeIds.addAll(missingIds);
    try {
      await Future.wait(
        missingIds.map((id) async {
          try {
            await ref
                .read(employee_state.employeeProvider.notifier)
                .getEmployee(id);
            final fetched = ref
                .read(employee_state.employeeProvider)
                .employees
                .where((e) => e.id == id)
                .toList();
            if (fetched.isNotEmpty) {
              final e = fetched.first;
              _employeeNameCache[id] = isDesktop
                  ? formatFullName(e.lastName, e.firstName, e.middleName)
                  : formatAbbreviatedName(
                      e.lastName,
                      e.firstName,
                      e.middleName,
                    );
              changed = true;
            }
          } catch (_) {
            // глушим ошибки загрузки конкретного id, продолжаем остальные
          } finally {
            _prefetchingEmployeeIds.remove(id);
          }
        }),
      );
    } finally {
      if (changed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
      }
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
    // Сначала используем переданную смену, если нет - ищем в провайдере
    final workAsync =
        widget.initialWork ?? ref.watch(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('works', 'update');

    // Проверка на владельца компании
    final userProfile = ref.watch(currentUserProfileProvider).profile;
    final isCompanyOwner = userProfile?.systemRole == 'owner';

    // Проверка на владельца смены
    final isOwner =
        userProfile != null && workAsync?.openedBy == userProfile.id;

    final bool canModify =
        ((isOwner && !isWorkClosed) || isCompanyOwner) && canUpdate;

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
                          'Нет сотрудников в смене. Добавьте сотрудника, нажав на "+"',
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: hours.length,
                        padding: ResponsiveUtils.isMobile(context)
                            ? WorkDetailDataSpacing.mobileTabListPadding.copyWith(
                                bottom: _listBottomPadding(context, canModify),
                              )
                            : EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                _listBottomPadding(context, canModify),
                              ),
                        itemBuilder: (context, i) {
                          final hour = hours[i];
                          final employeeName =
                              _employeeNameCache[hour.employeeId] ??
                              'Сотрудник ID: ${hour.employeeId}';
                          final hoursController = _ensureHourController(
                            hour.id,
                            hour.hours,
                          );

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
                                      context,
                                      hour,
                                    );
                                  }
                                : null,
                            onDismissed: canModify
                                ? (direction) {
                                    ref
                                        .read(
                                          _hoursProvider(
                                            widget.workId,
                                          ).notifier,
                                        )
                                        .delete(hour.id);
                                  }
                                : null,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (_isMassEdit && canModify)
                                      SizedBox(
                                        width: 80,
                                        child: GTTextField(
                                          controller: hoursController,
                                          textAlign: TextAlign.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              // ignore: deprecated_member_use
                                              RegExp(r'[0-9.,]'),
                                            ),
                                          ],
                                          onChanged: (_) =>
                                              _onHourFieldChanged(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                          borderRadius: 8,
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${hour.hours} ч',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle:
                                    hour.comment != null &&
                                        hour.comment!.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Комментарий: ${hour.comment}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
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

        // Быстрое заполнение часов — нижняя панель слева (рядом с FAB)
        if (canModify)
          Consumer(
            builder: (context, ref, _) {
              final hoursAsync = ref.watch(_hoursProvider(widget.workId));
              return hoursAsync.maybeWhen(
                data: (hours) {
                  if (hours.isEmpty) return const SizedBox.shrink();
                  return Positioned(
                    left: ResponsiveUtils.isMobile(context)
                        ? WorkDetailDataSpacing.mobileScrollHorizontal
                        : 16,
                    bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                    child: _buildPresetHoursDock(context, hours),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),

        // Кнопка добавления часов - только при праве редактирования
        if (canModify)
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom + 56 + 12,
            child: FloatingActionButton(
              heroTag: null,
              mini: true,
              onPressed: () async {
                if (!_isMassEdit) {
                  setState(() {
                    _isMassEdit = true;
                    _selectedPresetHours = null;
                    // Заполнить контроллеры актуальными значениями при входе в режим
                    final current = ref
                        .read(_hoursProvider(widget.workId))
                        .valueOrNull;
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
                  final current = ref
                      .read(_hoursProvider(widget.workId))
                      .valueOrNull;
                  if (current != null) {
                    final List<WorkHour> updated = [];
                    for (final h in current) {
                      final controller = _hourControllers[h.id];
                      if (controller == null) continue;
                      final parsed = parseAmount(controller.text);
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
                      _selectedPresetHours = null;
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
              heroTag: null,
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

  /// Нижний отступ списка под панель быстрого ввода и FAB.
  double _listBottomPadding(BuildContext context, bool canModify) {
    if (!canModify) return 16;
    return 16 + MediaQuery.viewPaddingOf(context).bottom + 132;
  }

  /// Нижняя панель быстрого заполнения часов всем сотрудникам.
  Widget _buildPresetHoursDock(BuildContext context, List<WorkHour> hours) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final outline = scheme.outline.withValues(alpha: 0.2);

    Widget presetChip(int presetHours) {
      final selected = _selectedPresetHours == presetHours;
      return Semantics(
        button: true,
        label: 'Заполнить всем $presetHours часов',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _applyPresetHours(presetHours, hours),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.14)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.45)
                      : outline,
                  width: selected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$presetHours ч',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 6),
              child: Text(
                'Всем',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            for (var i = 0; i < _presetHoursOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              presetChip(_presetHoursOptions[i]),
            ],
          ],
        ),
      ),
    );
  }

  /// Подтверждение удаления сотрудника из смены
  Future<bool?> _showDeleteHourConfirmationDialog(
    BuildContext context,
    WorkHour hour,
  ) async {
    return await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Подтверждение'),
        content: const Text(
          'Вы действительно хотите удалить сотрудника из смены?',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
