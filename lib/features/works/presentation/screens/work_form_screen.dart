import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/work_provider.dart';
import '../providers/work_hours_provider.dart';
import '../providers/month_groups_provider.dart';
import '../../domain/entities/work_hour.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/notifications/notification_service.dart';
import 'package:projectgt/features/works/presentation/utils/photo_upload_helper.dart';
import 'package:projectgt/features/works/presentation/widgets/photo_loading_dialog.dart';
import 'package:projectgt/core/utils/telegram_helper.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Экран создания новой смены.
class WorkFormScreen extends ConsumerStatefulWidget {
  /// Контроллер прокрутки для DraggableScrollableSheet.
  final ScrollController? scrollController;

  /// Родительский контекст для отображения snackbar и диалогов поверх модального окна.
  final BuildContext? parentContext;

  /// Создаёт экран формы создания новой смены.
  ///
  /// [scrollController] используется для управления прокруткой в модальных окнах.
  /// [parentContext] позволяет отображать сообщения поверх модального окна.
  const WorkFormScreen({
    super.key,
    this.scrollController,
    this.parentContext,
  });

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

    final objects = await ref.read(objectRepositoryProvider).getObjects();
    final profileObjectIds = profile.objectIds ?? [];
    final availableObjects =
        objects.where((o) => profileObjectIds.contains(o.id)).toList();

    if (availableObjects.length == 1) {
      setState(() {
        _selectedObjectId = availableObjects.first.id;
      });
      _updateOccupiedEmployees();
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
    final worksState = ref.read(worksProvider);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final openWorksToday = worksState.works.where((work) {
      final workDate = DateTime(work.date.year, work.date.month, work.date.day);
      return work.status.toLowerCase() == 'open' &&
          workDate.isAtSameMomentAs(todayStart);
    }).toList();

    final occupiedEmployeeIds = <String>{};

    for (final work in openWorksToday) {
      if (work.id != null) {
        try {
          final workHoursAsync = ref.read(workHoursProvider(work.id!));
          final workHours = workHoursAsync.valueOrNull ?? [];
          for (final hour in workHours) {
            occupiedEmployeeIds.add(hour.employeeId);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return occupiedEmployeeIds;
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
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Фото смены',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoOptionButton(
                  icon: Icons.photo_camera,
                  label: 'Камера',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                _PhotoOptionButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                if (_selectedPhotoFile != null || _selectedPhotoBytes != null)
                  _PhotoOptionButton(
                    icon: Icons.delete_outline,
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Сохранить смену
  Future<void> _saveWork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedObjectId == null || _selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(widget.parentContext ?? context).showSnackBar(
        SnackBar(
          content: const Text('Выберите объект и сотрудников'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    // Проверка обязательного фото смены
    if (_selectedPhotoFile == null && _selectedPhotoBytes == null) {
      ScaffoldMessenger.of(widget.parentContext ?? context).showSnackBar(
        SnackBar(
          content: const Text('Добавьте фото смены'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    try {
      // ✅ Загружаем фото через helper
      final uploadedPhotoUrl = await PhotoUploadHelper(
        context: context,
        ref: ref,
      ).uploadPhoto(
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
            if (profile == null) return;

            final createdWork = await notifier.addWork(
              date: DateTime.now(),
              objectId: _selectedObjectId!,
              openedBy: profile.id,
              status: 'open',
              photoUrl: photoUrl,
            );

            if (createdWork != null && createdWork.id != null) {
              // Планируем напоминания
              final slotTimes = (profile.object != null &&
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

              // Добавляем часы работников
              final hoursNotifier =
                  ref.read(workHoursProvider(createdWork.id!).notifier);

              for (final employeeId in _selectedEmployeeIds) {
                final workHour = WorkHour(
                  id: const Uuid().v4(),
                  workId: createdWork.id!,
                  employeeId: employeeId,
                  hours: 0,
                  comment: null,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await hoursNotifier.add(workHour);
              }

              // Отправляем PUSH админам
              try {
                final supabase = ref.read(supabaseClientProvider);
                final accessToken = supabase.auth.currentSession?.accessToken;
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
                final allEmployees =
                    await ref.read(employeeRepositoryProvider).getEmployees();

                final workerNames = <String>[];
                for (final empId in _selectedEmployeeIds) {
                  try {
                    final emp = allEmployees.firstWhere((e) => e.id == empId);
                    // Собираем ФИО из отдельных полей: Фамилия Имя Отчество
                    final fullName = [
                      emp.lastName,
                      emp.firstName,
                      if (emp.middleName != null && emp.middleName!.isNotEmpty)
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

                  await supabase.from('works').update({
                    'telegram_message_id': telegramResult['message_id']
                  }).eq('id', createdWork.id!);
                }
              } catch (e) {
                // Ошибка отправки отчета — не критично, работа уже создана
              }

              // Обновляем список смен
              ref.read(monthGroupsProvider.notifier).refresh().ignore();
            }
          } catch (e) {
            if (mounted) {
              SnackBarUtils.showError(context, 'Ошибка: $e');
            }
          }
        },
      );

      if (uploadedPhotoUrl == null) return;

      if (!mounted) return;

      // ✅ После нажатия "Готово" просто закрываем окно
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProfileProvider).profile;
    final allObjects = ref.watch(objectRepositoryProvider).getObjects();
    final allEmployees = ref.watch(employeeRepositoryProvider).getEmployees();
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return Material(
      color: theme.colorScheme.surface,
      child: _isLoadingOccupiedEmployees
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок (закреплен сверху)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: ModalUtils.buildModalHeader(
                        title: 'Открытие смены',
                        onClose: () => Navigator.pop(context),
                        theme: theme,
                      ),
                    ),

                    // Прокручиваемое содержимое
                Flexible(
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                        child: ModalUtils.buildAdaptiveFormContainer(
                          context: context,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Дата
                            _buildDateSection(theme, dateStr),
                            const SizedBox(height: 24),

                                // Объект и сотрудники
                                FutureBuilder(
                              future: Future.wait([allObjects, allEmployees]),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: CupertinoActivityIndicator());
                                    }

                                final objects =
                                    (snapshot.data![0] as List<ObjectEntity>);
                                    final employees =
                                        (snapshot.data![1] as List<Employee>);
                                    final profileObjectIds =
                                        profile?.objectIds ?? [];
                                    final availableObjects = objects
                                    .where(
                                        (o) => profileObjectIds.contains(o.id))
                                        .toList();

                                    return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Выбор объекта
                                    _buildObjectSelector(
                                      availableObjects,
                                      theme,
                                    ),
                                    const SizedBox(height: 24),

                                    // Сотрудники
                                    Text(
                                      'Сотрудники',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Отображаются только активные сотрудники',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEmployeesList(employees, theme),
                                    const SizedBox(height: 24),

                                    // Фото смены
                                    Text(
                                      'Фото смены',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPhotoSection(theme),
                                    const SizedBox(height: 24),

                                    // Кнопки управления (теперь внутри скролла, под фото)
                                    _buildActionButtons(context),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final buttonHeight = isMobile ? 44.0 : 48.0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(buttonHeight),
              shape: const StadiumBorder(),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoadingOccupiedEmployees
                ? null
                : () {
                    if (_selectedObjectId != null &&
                        _selectedEmployeeIds.isNotEmpty &&
                        !_isLoadingOccupiedEmployees) {
                      _saveWork();
                    }
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(buttonHeight),
              shape: const StadiumBorder(),
              elevation: isMobile ? 4 : 1,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: _isLoadingOccupiedEmployees
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CupertinoActivityIndicator(),
                  )
                : const Text('Открыть'),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(ThemeData theme, String dateStr) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 20,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Text(
          dateStr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectSelector(
      List<ObjectEntity> availableObjects, ThemeData theme) {
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
          final selectedObject = availableObjects
              .firstWhere((obj) => obj.name == selectedName);
                                              setState(() {
            _selectedObjectId = selectedObject.id;
                                                _selectedEmployeeIds.clear();
                                              });
                                              _updateOccupiedEmployees();
                                            } else {
                                              setState(() {
                                                _selectedObjectId = null;
                                                _selectedEmployeeIds.clear();
            _cachedOccupiedEmployeeIds = null;
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
    final hasPhoto =
        _selectedPhotoFile != null || _selectedPhotoBytes != null;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
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
                      errorBuilder: (context, error, stackTrace) => Icon(
                                                        Icons.broken_image,
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
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
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
                      Icons.add_a_photo_outlined,
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
    );
  }

  /// Строит список сотрудников
  Widget _buildEmployeesList(List<Employee> employees, ThemeData theme) {
    if (_selectedObjectId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
        child: Text(
          'Выберите объект для отображения сотрудников',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isLoadingOccupiedEmployees) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    final occupiedEmployeeIds = _cachedOccupiedEmployeeIds ?? <String>{};

    final baseFilteredEmployees = employees
        .where((e) => e.objectIds.contains(_selectedObjectId))
        .where((e) => e.status == EmployeeStatus.working)
        .toList();

    final availableEmployees = baseFilteredEmployees
        .where((e) => !occupiedEmployeeIds.contains(e.id))
        .toList();

    if (availableEmployees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
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
    }

    return ListView.separated(
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
            });
          },
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
                      Icons.check,
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
                    '${employee.lastName} ${employee.firstName}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (employee.middleName != null &&
                      employee.middleName!.isNotEmpty)
                    Text(
                      employee.middleName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? (isDark ? Colors.black54 : Colors.white70)
                            : theme.colorScheme.secondary,
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
