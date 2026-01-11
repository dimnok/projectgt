import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/core/notifications/notification_service.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/utils/telegram_helper.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/employee.dart' as emp_domain;
import 'package:projectgt/domain/entities/employee.dart' show Employee;
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/works/domain/entities/work_hour.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_hours_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_provider.dart';
import 'package:projectgt/features/works/presentation/utils/photo_upload_helper.dart';
import 'package:projectgt/features/works/presentation/widgets/photo_loading_dialog.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as emp_state;
import 'package:uuid/uuid.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Экран создания новой смены.
class WorkFormScreen extends ConsumerStatefulWidget {
  /// Родительский контекст для отображения snackbar и диалогов поверх модального окна.
  final BuildContext? parentContext;

  /// Создаёт экран формы создания новой смены.
  const WorkFormScreen({super.key, this.parentContext});

  @override
  ConsumerState<WorkFormScreen> createState() => _WorkFormScreenState();
}

class _WorkFormScreenState extends ConsumerState<WorkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedPhotoFile; // Локальный файл до загрузки (mobile)
  Uint8List? _selectedPhotoBytes; // Локальные байты (web)

  // Состояния формы
  String? _selectedObjectId;
  final List<String> _selectedEmployeeIds = [];

  // Кеширование для предотвращения мерцания
  Set<String>? _cachedOccupiedEmployeeIds;
  bool _isLoadingOccupiedEmployees = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOccupiedEmployees();
      _autoSelectSingleObject();
    });
  }

  /// Автоматически выбирает объект, если доступен только один
  Future<void> _autoSelectSingleObject() async {
    final profile = ref.read(currentUserProfileProvider).profile;
    if (profile == null) return;

    // Используем уже загруженные данные из провайдера
    final objectsState = ref.read(objectProvider);
    final objects = objectsState.objects;

    if (objects.isEmpty) return;

    final profileObjectIds = profile.objectIds ?? [];
    final availableObjects = objects
        .where((o) => profileObjectIds.contains(o.id))
        .toList();

    if (availableObjects.length == 1) {
      if (mounted) {
        setState(() {
          _selectedObjectId = availableObjects.first.id;
        });
      }
    }
  }

  /// Обновляет список занятых сотрудников с кешированием
  Future<void> _updateOccupiedEmployees() async {
    if (_isLoadingOccupiedEmployees) return;

    setState(() {
      _isLoadingOccupiedEmployees = true;
    });

    try {
      final occupiedIds = await _getEmployeesInOpenShifts();
      if (mounted) {
        setState(() {
          _cachedOccupiedEmployeeIds = occupiedIds;
          _isLoadingOccupiedEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedOccupiedEmployeeIds = <String>{};
          _isLoadingOccupiedEmployees = false;
        });
      }
    }
  }

  /// Получает список ID сотрудников в открытых сменах на сегодня
  Future<Set<String>> _getEmployeesInOpenShifts() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      final today = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(today);

      // Получаем открытые смены на сегодня и сразу джойним часы сотрудников
      // Используем !inner для фильтрации только тех смен, которые подходят под условия
      var query = supabase
          .from('works')
          .select('work_hours(employee_id)')
          .eq('date', dateStr)
          .eq('status', 'open');

      if (activeCompanyId != null) {
        query = query.eq('company_id', activeCompanyId);
      }

      final response = await query;

      final occupiedEmployeeIds = <String>{};

      for (final work in response) {
        final hours = work['work_hours'] as List<dynamic>?;
        if (hours != null) {
          for (final hour in hours) {
            occupiedEmployeeIds.add(hour['employee_id'] as String);
          }
        }
      }

      return occupiedEmployeeIds;
    } catch (e) {
      debugPrint('Error getting occupied employees: $e');
      return {};
    }
  }

  /// Выбор фото
  Future<void> _pickPhoto(ImageSource source) async {
    final photoService = ref.read(photoServiceProvider);
    if (kIsWeb) {
      final bytes = await photoService.pickImageBytes(source);
      if (bytes == null) return;
      if (!mounted) return;
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoFile = null;
      });
    } else {
      final file = await photoService.pickImage(source);
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _selectedPhotoFile = file;
        _selectedPhotoBytes = null;
      });
    }
  }

  /// Показать опции выбора фото
  void _showPhotoOptions() {
    final theme = Theme.of(context);
    // Используем MobileBottomSheetContent для вложенного диалога выбора фото
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MobileBottomSheetContent(
        title: 'Фото смены',
        footer: GTTextButton(
          text: 'Отмена',
          onPressed: () => Navigator.pop(context),
          color: theme.colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PhotoOptionButton(
              icon: CupertinoIcons.camera,
              label: 'Камера',
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            _PhotoOptionButton(
              icon: CupertinoIcons.photo,
              label: 'Галерея',
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_selectedPhotoFile != null || _selectedPhotoBytes != null)
              _PhotoOptionButton(
                icon: CupertinoIcons.delete,
                label: 'Удалить',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPhotoFile = null;
                    _selectedPhotoBytes = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Сохранить смену
  Future<void> _saveWork() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // ✅ Загружаем фото через helper
      final uploadedPhotoUrl =
          await PhotoUploadHelper(context: context, ref: ref).uploadPhoto(
            photoType: PhotoType.morning,
            entity: 'shift',
            entityId: _selectedObjectId!,
            displayName: 'morning',
            photoBytes: _selectedPhotoBytes,
            photoFile: _selectedPhotoFile,
            // ✅ Все длительные операции выполняются ВО ВРЕМЯ диалога загрузки
            onLoadingComplete: (String photoUrl) async {
              try {
                final notifier = ref.read(worksProvider.notifier);
                final profile = ref.read(currentUserProfileProvider).profile;
                final activeCompanyId = ref.read(activeCompanyIdProvider);

                if (profile == null || activeCompanyId == null) return;

                final createdWork = await notifier.addWork(
                  companyId: activeCompanyId,
                  date: DateTime.now(),
                  objectId: _selectedObjectId!,
                  openedBy: profile.id,
                  status: 'open',
                  photoUrl: photoUrl,
                );

                if (createdWork != null && createdWork.id != null) {
                  // Планируем напоминания
                  final slotTimes =
                      (profile.object != null &&
                          profile.object!.containsKey('slot_times'))
                      ? (profile.object!['slot_times'] as List?)?.cast<String>()
                      : null;

                  await ref
                      .read(notificationServiceProvider)
                      .scheduleShiftReminders(
                        shiftId: createdWork.id!,
                        date: DateTime.now(),
                        slotTimesHHmm: slotTimes,
                      );

                  // Добавляем часы работников параллельно
                  final hoursNotifier = ref.read(
                    workHoursProvider(createdWork.id!).notifier,
                  );

                  await Future.wait(
                    _selectedEmployeeIds.map((employeeId) {
                      final workHour = WorkHour(
                        id: const Uuid().v4(),
                        companyId: activeCompanyId,
                        workId: createdWork.id!,
                        employeeId: employeeId,
                        hours: 0,
                        comment: null,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      return hoursNotifier.add(workHour);
                    }),
                  );

                  // Отправляем PUSH админам
                  try {
                    final supabase = ref.read(supabaseClientProvider);
                    final accessToken =
                        supabase.auth.currentSession?.accessToken;
                    if (accessToken != null) {
                      await supabase.functions.invoke(
                        'send_admin_work_event',
                        body: {'action': 'open', 'work_id': createdWork.id!},
                        headers: {'Authorization': 'Bearer $accessToken'},
                      );
                    }
                  } catch (_) {}

                  // Отправляем утренний отчет в Telegram
                  try {
                    // Даём время на синхронизацию работников в БД
                    await Future.delayed(const Duration(milliseconds: 1000));

                    // Получаем ФИО всех выбранных сотрудников из локального кеша
                    final allEmployees = await ref
                        .read(employeeRepositoryProvider)
                        .getEmployees();

                    final workerNames = <String>[];
                    for (final empId in _selectedEmployeeIds) {
                      try {
                        final emp = allEmployees.firstWhere(
                          (e) => e.id == empId,
                        );
                        // Собираем ФИО из отдельных полей: Фамилия Имя Отчество
                        final fullName = [
                          emp.lastName,
                          emp.firstName,
                          if (emp.middleName != null &&
                              emp.middleName!.isNotEmpty)
                            emp.middleName,
                        ].join(' ');
                        if (fullName.isNotEmpty) {
                          workerNames.add(fullName);
                        }
                      } catch (e) {
                        // Сотрудник не найден, пропускаем
                      }
                    }

                    final telegramResult =
                        await TelegramHelper.sendWorkOpeningReport(
                          createdWork.id!,
                          workerNames: workerNames,
                        );

                    if (telegramResult != null &&
                        telegramResult['success'] == true &&
                        telegramResult['message_id'] != null) {
                      // Сохраняем message_id в БД для связывания с вечерним отчетом
                      final supabase = ref.read(supabaseClientProvider);

                      await supabase
                          .from('works')
                          .update({
                            'telegram_message_id': telegramResult['message_id'],
                          })
                          .eq('id', createdWork.id!);
                    }
                  } catch (e) {
                    // Ошибка отправки отчета — не критично, работа уже создана
                  }

                  // Обновляем список смен
                  ref.read(monthGroupsProvider.notifier).refresh().ignore();
                }
              } catch (e) {
                if (mounted) {
                  AppSnackBar.show(
                    context: context,
                    message: 'Ошибка: $e',
                    kind: AppSnackBarKind.error,
                  );
                }
              }
            },
          );

      if (uploadedPhotoUrl == null) return;

      if (!mounted) return;

      // ✅ После нажатия "Готово" закрываем форму создания смены.
      // Используем небольшую задержку, чтобы избежать конфликта с закрытием диалога успеха в PhotoUploadHelper.
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    // Основной контент (спиннер или форма)
    final Widget content = _isLoadingOccupiedEmployees
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CupertinoActivityIndicator(radius: 16),
            ),
          )
        : _buildFormContent(context, theme);

    // Кнопки действий (показываем только если не загружается)
    final Widget? footer = _isLoadingOccupiedEmployees
        ? null
        : _buildFooter(context);

    final dateStr = formatRuDate(DateTime.now());

    if (isMobile) {
      return MobileBottomSheetContent(
        title: 'Открытие смены $dateStr',
        footer: footer,
        child: content,
      );
    } else {
      return Center(
        child: DesktopDialogContent(
          title: 'Открытие смены $dateStr',
          footer: footer,
          child: content,
        ),
      );
    }
  }

  Widget _buildFormContent(BuildContext context, ThemeData theme) {
    final profile = ref.watch(currentUserProfileProvider).profile;

    // Используем провайдеры вместо прямых вызовов репозиториев
    final objectsState = ref.watch(objectProvider);
    // Используем правильное имя провайдера, которое определено в employee_state.dart
    final employeesState = ref.watch(emp_state.employeeProvider);

    // Показываем лоадер, если данные еще грузятся
    if (objectsState.status == ObjectStatus.loading ||
        employeesState.status == emp_state.EmployeeStatus.loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final objects = objectsState.objects;
    final employees = employeesState.employees;
    final profileObjectIds = profile?.objectIds ?? [];
    final availableObjects = objects
        .where((o) => profileObjectIds.contains(o.id))
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Выбор объекта
          _buildObjectSelector(availableObjects, theme),
          const SizedBox(height: 24),

          // Сотрудники
          Text(
            'Сотрудники',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Отображаются только активные сотрудники',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 12),
          _buildEmployeesList(employees, theme),
          const SizedBox(height: 24),

          // Фото смены
          Text(
            'Фото смены',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPhotoSection(theme),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: 'Открыть',
            isLoading: _isLoadingOccupiedEmployees,
            onPressed: _isLoadingOccupiedEmployees ? null : _saveWork,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectSelector(
    List<ObjectEntity> availableObjects,
    ThemeData theme,
  ) {
    return GTStringDropdown(
      items: availableObjects.map((obj) => obj.name).toList(),
      selectedItem: _selectedObjectId != null
          ? availableObjects
                .where((obj) => obj.id == _selectedObjectId)
                .map((obj) => obj.name)
                .firstOrNull
          : null,
      onSelectionChanged: (selectedName) {
        if (selectedName != null) {
          final selectedObject = availableObjects.firstWhere(
            (obj) => obj.name == selectedName,
          );
          setState(() {
            _selectedObjectId = selectedObject.id;
            _selectedEmployeeIds.clear();
          });
        } else {
          setState(() {
            _selectedObjectId = null;
            _selectedEmployeeIds.clear();
          });
        }
      },
      labelText: 'Объект',
      hintText: availableObjects.length == 1
          ? 'Объект выбран автоматически'
          : 'Выберите объект',
      allowCustomInput: false,
      validator: (value) {
        if (_selectedObjectId == null) {
          return 'Выберите объект';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    final hasPhoto = _selectedPhotoFile != null || _selectedPhotoBytes != null;
    final isDark = theme.brightness == Brightness.dark;

    return FormField<bool>(
      key: ValueKey(
        hasPhoto,
      ), // Сброс состояния ошибки при изменении наличия фото
      initialValue: hasPhoto,
      validator: (value) {
        if (!hasPhoto) {
          return 'Добавьте фото смены';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _selectedObjectId != null ? _showPhotoOptions : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  border: Border.all(
                    color: hasPhoto
                        ? Colors.transparent
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_selectedPhotoBytes != null)
                            Image.memory(
                              _selectedPhotoBytes!,
                              fit: BoxFit.cover,
                            )
                          else
                            Image.file(
                              _selectedPhotoFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    color: theme.colorScheme.error,
                                    size: 48,
                                  ),
                            ),
                          // Градиент для читаемости кнопки удаления
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.4),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.camera_on_rectangle,
                              size: 48,
                              color: _selectedObjectId != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedObjectId != null
                                  ? 'Добавить фото'
                                  : 'Сначала выберите объект',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _selectedObjectId != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_selectedObjectId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '* Обязательно',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Строит список сотрудников
  Widget _buildEmployeesList(List<Employee> employees, ThemeData theme) {
    return FormField<List<String>>(
      initialValue: _selectedEmployeeIds,
      validator: (value) {
        if (_selectedObjectId != null && _selectedEmployeeIds.isEmpty) {
          return 'Выберите хотя бы одного сотрудника';
        }
        return null;
      },
      builder: (state) {
        Widget content;
        if (_selectedObjectId == null) {
          content = Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Выберите объект для отображения сотрудников',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (_isLoadingOccupiedEmployees) {
          content = const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CupertinoActivityIndicator(),
            ),
          );
        } else {
          final occupiedEmployeeIds = _cachedOccupiedEmployeeIds ?? <String>{};

          final baseFilteredEmployees = employees
              .where((e) => e.objectIds.contains(_selectedObjectId))
              .where((e) => e.status == emp_domain.EmployeeStatus.working)
              .toList();

          final availableEmployees = baseFilteredEmployees
              .where((e) => !occupiedEmployeeIds.contains(e.id))
              .toList();

          if (availableEmployees.isEmpty) {
            content = Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Нет доступных сотрудников',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Все сотрудники на этом объекте уже заняты или не найдены',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            content = ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableEmployees.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final emp = availableEmployees[index];
                final isSelected = _selectedEmployeeIds.contains(emp.id);

                return _EmployeeSelectionTile(
                  employee: emp,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedEmployeeIds.remove(emp.id);
                      } else {
                        _selectedEmployeeIds.add(emp.id);
                      }
                      // Уведомляем форму об изменении для скрытия ошибки валидации
                      state.didChange(_selectedEmployeeIds);
                    });
                  },
                );
              },
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeSelectionTile extends StatelessWidget {
  final Employee employee;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmployeeSelectionTile({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Чекбокс (кастомный)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green : theme.colorScheme.outline,
                  width: 2,
                ),
                color: isSelected ? Colors.green : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ResponsiveUtils.isDesktop(context)
                        ? formatFullName(
                          employee.lastName,
                          employee.firstName,
                          employee.middleName,
                        )
                        : formatAbbreviatedName(
                          employee.lastName,
                          employee.firstName,
                          employee.middleName,
                        ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет кнопки выбора фото
class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
