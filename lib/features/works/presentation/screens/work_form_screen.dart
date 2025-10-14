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
  bool _isLoading = false;
  String? _photoUrl;
  File? _selectedPhotoFile; // Локальный файл до загрузки (mobile)
  Uint8List? _selectedPhotoBytes; // Локальные байты (web)

  // Контроллеры (не используются с GTDropdown)

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

  @override
  void dispose() {
    super.dispose();
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
        _photoUrl = null;
      });
    } else {
      final file = await photoService.pickImage(source);
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _selectedPhotoFile = file;
        _selectedPhotoBytes = null;
        _photoUrl = null;
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
                if (_photoUrl != null && _photoUrl!.isNotEmpty)
                  _PhotoOptionButton(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() {
                        _photoUrl = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать просмотр локального фото с возможностью замены или удаления
  void _showLocalPhotoViewer(BuildContext context) {
    if (_selectedPhotoFile == null) return;

    final theme = Theme.of(context);
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Фото на весь экран
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  _selectedPhotoFile!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.error,
                    size: 64,
                  ),
                ),
              ),
            ),
            // Кнопка закрытия
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            // Панель действий снизу
            Positioned(
              bottom: MediaQuery.of(context).viewPadding.bottom + 32,
              left: 32,
              right: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Заменить фото
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPhotoOptions();
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Заменить',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  // Удалить фото
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedPhotoFile = null;
                        });
                      },
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.white),
                      label: const Text('Удалить',
                          style: TextStyle(color: Colors.white)),
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

  /// Сохранить смену
  Future<void> _saveWork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedObjectId == null || _selectedEmployeeIds.isEmpty) {
      SnackBarUtils.showWarningOverlay(
          widget.parentContext ?? context, 'Выберите объект и сотрудников');
      return;
    }

    // Проверка обязательного фото смены
    if (_selectedPhotoFile == null &&
        _selectedPhotoBytes == null &&
        _photoUrl == null) {
      SnackBarUtils.showWarningOverlay(
          widget.parentContext ?? context, 'Добавьте фото смены');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(worksProvider.notifier);
      final profile = ref.read(currentUserProfileProvider).profile;
      if (profile == null) return;

      // Загружаем фото в облако, если есть выбранный файл
      String? uploadedPhotoUrl;
      final photoService = ref.read(photoServiceProvider);
      if (_selectedPhotoBytes != null) {
        uploadedPhotoUrl = await photoService.uploadPhotoBytes(
          entity: 'shift',
          id: _selectedObjectId!,
          bytes: _selectedPhotoBytes!,
          displayName: 'morning',
        );
      } else if (_selectedPhotoFile != null) {
        uploadedPhotoUrl = await photoService.uploadPhoto(
          entity: 'shift',
          id: _selectedObjectId!,
          file: _selectedPhotoFile!,
          displayName: 'morning',
        );
      }

      final createdWork = await notifier.addWork(
        date: DateTime.now(),
        objectId: _selectedObjectId!,
        openedBy: profile.id,
        status: 'open',
        photoUrl: uploadedPhotoUrl,
      );

      if (createdWork != null && createdWork.id != null) {
        // Планируем напоминания на сегодня для этой смены с учётом настроек профиля
        final currentProfile = ref.read(currentUserProfileProvider).profile;
        final slotTimes = (currentProfile?.object != null &&
                currentProfile!.object!.containsKey('slot_times'))
            ? (currentProfile.object!['slot_times'] as List?)?.cast<String>()
            : null;

        await ref.read(notificationServiceProvider).scheduleShiftReminders(
              shiftId: createdWork.id!,
              date: DateTime.now(),
              slotTimesHHmm: slotTimes,
            );

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

        // Отправка PUSH админам о открытии смены через Edge Function
        try {
          final supabase = ref.read(supabaseClientProvider);
          final accessToken = supabase.auth.currentSession?.accessToken;
          if (accessToken != null) {
            final resp = await supabase.functions.invoke(
              'send_admin_work_event',
              body: {
                'action': 'open',
                'work_id': createdWork.id!,
              },
              headers: {
                'Authorization': 'Bearer $accessToken',
              },
            );
            debugPrint(
                'send_admin_work_event(open): status=${resp.status}, data=${resp.data}');
          }
        } catch (_) {
          // не блокируем UX из‑за уведомления
        }
      }

      if (mounted) {
        // Кэшируем зависимости от контекста ДО async операции
        final navigator = Navigator.of(context);
        final scaffoldMessenger = widget.parentContext != null
            ? ScaffoldMessenger.of(widget.parentContext!)
            : ScaffoldMessenger.of(context);

        // Обновляем список смен в monthGroupsProvider для отображения новой смены
        await ref.read(monthGroupsProvider.notifier).refresh();

        // Проверяем mounted ПОСЛЕ async операции
        if (!mounted) return;

        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Смена успешно открыта'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = widget.parentContext != null
            ? ScaffoldMessenger.of(widget.parentContext!)
            : ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Stack(
              children: [
                // Основное содержимое
                Column(
                  children: [
                    // Заголовок (закреплен сверху)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                        padding: EdgeInsets.fromLTRB(
                          24.0,
                          24.0,
                          24.0,
                          100.0 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ModalUtils.buildAdaptiveFormContainer(
                          context: context,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Дата
                                TextFormField(
                                  initialValue: dateStr,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Дата',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Объект и сотрудники
                                FutureBuilder(
                                  future:
                                      Future.wait([allObjects, allEmployees]),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: CupertinoActivityIndicator());
                                    }

                                    final objects = (snapshot.data![0]
                                        as List<ObjectEntity>);
                                    final employees =
                                        (snapshot.data![1] as List<Employee>);
                                    final profileObjectIds =
                                        profile?.objectIds ?? [];
                                    final availableObjects = objects
                                        .where((o) =>
                                            profileObjectIds.contains(o.id))
                                        .toList();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Выбор объекта
                                        GTStringDropdown(
                                          items: availableObjects
                                              .map((obj) => obj.name)
                                              .toList(),
                                          selectedItem:
                                              _selectedObjectId != null
                                                  ? availableObjects
                                                      .where((obj) =>
                                                          obj.id ==
                                                          _selectedObjectId)
                                                      .map((obj) => obj.name)
                                                      .firstOrNull
                                                  : null,
                                          onSelectionChanged: (selectedName) {
                                            if (selectedName != null) {
                                              final selectedObject =
                                                  availableObjects.firstWhere(
                                                      (obj) =>
                                                          obj.name ==
                                                          selectedName);
                                              setState(() {
                                                _selectedObjectId =
                                                    selectedObject.id;
                                                _selectedEmployeeIds.clear();
                                              });
                                              _updateOccupiedEmployees();
                                            } else {
                                              setState(() {
                                                _selectedObjectId = null;
                                                _selectedEmployeeIds.clear();
                                                _cachedOccupiedEmployeeIds =
                                                    null;
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
                                        ),
                                        const SizedBox(height: 16),

                                        // Сотрудники
                                        Text('Сотрудники',
                                            style: theme.textTheme.bodyLarge),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Отображаются только сотрудники со статусом "Работает"',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.secondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEmployeesList(employees, theme),
                                        const SizedBox(height: 16),

                                        // Фото смены
                                        if (_selectedPhotoFile != null ||
                                            _selectedPhotoBytes != null)
                                          // Превью локального фото (при клике открывается просмотр)
                                          GestureDetector(
                                            onTap: () =>
                                                _showLocalPhotoViewer(context),
                                            child: Container(
                                              width: double.infinity,
                                              height: 200,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: theme
                                                      .colorScheme.outline
                                                      .withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: _selectedPhotoBytes !=
                                                        null
                                                    ? Image.memory(
                                                        _selectedPhotoBytes!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        _selectedPhotoFile!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Icon(
                                                          Icons.broken_image,
                                                          color: theme
                                                              .colorScheme
                                                              .error,
                                                          size: 48,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          )
                                        else
                                          // Кнопка добавления фото (обязательное поле)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed:
                                                    _selectedObjectId != null
                                                        ? _showPhotoOptions
                                                        : null,
                                                icon: const Icon(
                                                    Icons.add_a_photo),
                                                label: Text(_selectedObjectId !=
                                                        null
                                                    ? 'Добавить фото смены *'
                                                    : 'Сначала выберите объект'),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize:
                                                      const Size.fromHeight(48),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  side: BorderSide(
                                                    color: theme
                                                        .colorScheme.error
                                                        .withValues(alpha: 0.8),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Фото смены обязательно',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      theme.colorScheme.error,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(
                                            height:
                                                100), // Место для плавающих кнопок
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

                // Плавающие кнопки (как в модуле сотрудников)
                ModalUtils.buildFloatingButtons(
                  onSave: () {
                    if (_selectedObjectId != null &&
                        _selectedEmployeeIds.isNotEmpty &&
                        !_isLoading) {
                      _saveWork();
                    }
                  },
                  onCancel: () => Navigator.pop(context),
                  isLoading: _isLoading,
                  saveText: 'Открыть смену *',
                  scrollController: widget.scrollController,
                ),
              ],
            ),
    );
  }

  /// Строит список сотрудников
  Widget _buildEmployeesList(List<Employee> employees, ThemeData theme) {
    if (_selectedObjectId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Выберите объект для отображения сотрудников',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
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
        padding: const EdgeInsets.all(16),
        child: Text(
          'Нет доступных сотрудников для выбранного объекта',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: availableEmployees.map((emp) {
        final isSelected = _selectedEmployeeIds.contains(emp.id);
        return CheckboxListTile(
          value: isSelected,
          title: Text(
              '${emp.lastName} ${emp.firstName}${emp.middleName != null && emp.middleName!.isNotEmpty ? ' ${emp.middleName}' : ''}'),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _selectedEmployeeIds.add(emp.id);
              } else {
                _selectedEmployeeIds.remove(emp.id);
              }
            });
          },
        );
      }).toList(),
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
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
