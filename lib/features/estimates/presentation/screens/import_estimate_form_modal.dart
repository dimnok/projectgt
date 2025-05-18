import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data';
import 'package:projectgt/data/models/estimate_model.dart';
import 'package:projectgt/data/services/excel_estimate_service.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import 'package:projectgt/core/utils/notifications_service.dart';
import 'package:go_router/go_router.dart';

/// Модальное окно для импорта сметы из Excel.
///
/// Позволяет выбрать объект, договор, название сметы и Excel-файл для импорта.
/// Предоставляет возможность скачать шаблон Excel и просмотреть данные перед импортом.
class ImportEstimateFormModal extends StatefulWidget {
  /// Провайдер состояния Riverpod.
  final WidgetRef ref;

  /// Колбэк при успешном импорте.
  final VoidCallback onSuccess;

  /// Колбэк при отмене импорта.
  final VoidCallback onCancel;

  /// Создаёт модальное окно импорта сметы.
  const ImportEstimateFormModal({
    required this.ref,
    required this.onSuccess,
    required this.onCancel,
    super.key,
  });

  @override
  State<ImportEstimateFormModal> createState() => _ImportEstimateFormModalState();
}

class _ImportEstimateFormModalState extends State<ImportEstimateFormModal> {
  String? selectedObjectId;
  String? selectedContractId;
  String? estimateName;
  PlatformFile? pickedFile;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  late final TextEditingController _objectController;
  late final TextEditingController _contractController;
  late final TextEditingController _estimateNameController;
  
  // Список уникальных названий смет для выбора
  List<String> _existingEstimateTitles = [];
  // Отфильтрованные названия смет на основе выбранного объекта и договора
  List<String> _filteredEstimateTitles = [];
  // Флаг загрузки списка смет
  bool _loadingEstimateTitles = false;
  
  // Состояние предпросмотра
  bool _showPreview = false;
  ExcelPreviewResult? _previewData;
  ExcelValidationResult? _validationResult;
  int _currentStep = 0; // 0 - выбор файла, 1 - предпросмотр, 2 - импорт
  bool _isImporting = false;
  int _importedRows = 0;
  int _totalRows = 0;
  String _importStatus = '';
  bool _validationPassed = false;
  
  // Форматтер для денежных значений
  final NumberFormat moneyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _objectController = TextEditingController();
    _contractController = TextEditingController();
    _estimateNameController = TextEditingController();
    
    // Загружаем список существующих смет при инициализации
    _loadExistingEstimateTitles();
  }

  @override
  void dispose() {
    _objectController.dispose();
    _contractController.dispose();
    _estimateNameController.dispose();
    super.dispose();
  }

  /// Загружает список существующих имен смет из базы данных
  Future<void> _loadExistingEstimateTitles() async {
    setState(() => _loadingEstimateTitles = true);
    
    try {
      // Получаем список смет из состояния приложения
      final estimates = widget.ref.read(estimateNotifierProvider).estimates;
      
      // Извлекаем уникальные названия смет
      final titles = <String>{};
      for (final estimate in estimates) {
        if (estimate.estimateTitle != null && estimate.estimateTitle!.isNotEmpty) {
          titles.add(estimate.estimateTitle!);
        }
      }
      
      setState(() {
        _existingEstimateTitles = titles.toList()..sort();
        _filteredEstimateTitles = _existingEstimateTitles;
        _loadingEstimateTitles = false;
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке названий смет: $e');
      setState(() => _loadingEstimateTitles = false);
    }
  }
  
  /// Фильтрует сметы на основе выбранного объекта и договора
  void _filterEstimates() {
    final estimates = widget.ref.read(estimateNotifierProvider).estimates;
    
    if (selectedObjectId == null) {
      setState(() {
        _filteredEstimateTitles = _existingEstimateTitles;
      });
      return;
    }
    
    final filteredTitles = <String>{};
    for (final estimate in estimates) {
      if (estimate.estimateTitle != null && 
          estimate.estimateTitle!.isNotEmpty &&
          estimate.objectId == selectedObjectId &&
          (selectedContractId == null || estimate.contractId == selectedContractId)) {
        filteredTitles.add(estimate.estimateTitle!);
      }
    }
    
    setState(() {
      _filteredEstimateTitles = filteredTitles.toList()..sort();
    });
  }
  
  /// Возвращает список договоров, отфильтрованных по выбранному объекту
  List<String> _getFilteredContracts(String pattern) {
    final contractState = widget.ref.read(contractProvider);
    
    if (selectedObjectId == null) {
      return contractState.contracts
        .where((c) => c.number.toLowerCase().contains(pattern.toLowerCase()))
        .map((c) => c.number)
        .toList();
    }
    
    // Фильтрация договоров по выбранному объекту
    return contractState.contracts
      .where((c) => c.objectId == selectedObjectId && 
                    c.number.toLowerCase().contains(pattern.toLowerCase()))
      .map((c) => c.number)
      .toList();
  }
  
  /// Сбрасывает выбранный договор при изменении объекта
  void _resetContractSelection() {
    setState(() {
      selectedContractId = null;
      _contractController.text = '';
    });
  }
  
  /// Обновляет информацию о смете на основе выбранного имени
  void _updateEstimateInfo(String title) {
    final estimates = widget.ref.read(estimateNotifierProvider).estimates;
    
    // Находим первую запись с указанным названием сметы
    final selectedEstimate = estimates.firstWhere(
      (e) => e.estimateTitle == title,
      orElse: () => estimates.first,
    );
    
    // Находим информацию об объекте и договоре
    final objectId = selectedEstimate.objectId;
    final contractId = selectedEstimate.contractId;
    
    // Если объект и договор найдены, обновляем форму
    if (objectId != null) {
      final objects = widget.ref.read(objectProvider).objects;
      final selectedObject = objects.firstWhere(
        (o) => o.id == objectId,
        orElse: () => objects.first,
      );
      
      setState(() {
        selectedObjectId = objectId;
        _objectController.text = selectedObject.name;
      });
    }
    
    if (contractId != null) {
      final contracts = widget.ref.read(contractProvider).contracts;
      final selectedContract = contracts.firstWhere(
        (c) => c.id == contractId,
        orElse: () => contracts.first,
      );
      
      setState(() {
        selectedContractId = contractId;
        _contractController.text = selectedContract.number;
      });
    }
  }

  /// Скачивает шаблон Excel для заполнения
  Future<void> _downloadTemplate() async {
    try {
      setState(() => isLoading = true);
      debugPrint('Загрузка шаблона из файловой системы');
      final bytes = await ExcelEstimateService.loadTemplateFromFileSystem();
      debugPrint('Шаблон загружен, размер: ${bytes.length} байт');
      
      if (kIsWeb) {
        // Веб-версия - используем file_saver
        await FileSaver.instance.saveFile(
          name: 'estimate_template.xlsx',
          bytes: bytes,
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        // Мобильная версия - используем path_provider и share_plus
        final directory = await path_provider.getTemporaryDirectory();
        final path = '${directory.path}/estimate_template.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([XFile(path)], text: 'Шаблон сметы для заполнения');
      }
      
      if (!mounted) return;
      NotificationsService.showSuccessNotification(
        context, 
        'Шаблон сметы успешно скачан'
      );
    } catch (e) {
      if (!mounted) return;
      NotificationsService.showErrorNotification(
        context, 
        'Ошибка при скачивании шаблона: $e'
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  
  /// Выбирает Excel-файл для импорта
  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          pickedFile = result.files.single;
          _showPreview = false;
          _previewData = null;
          _validationResult = null;
          _validationPassed = false;
        });
        
        // Валидация и предпросмотр
        await _validateFile();
      }
    } catch (e) {
      if (!mounted) return;
      NotificationsService.showErrorNotification(
        context, 
        'Ошибка при выборе файла: $e'
      );
    }
  }
  
  /// Валидирует выбранный файл
  Future<void> _validateFile() async {
    if (pickedFile?.bytes == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final bytes = Uint8List.fromList(pickedFile!.bytes!);
      
      // Валидация содержимого
      final validationResult = ExcelEstimateService.validateExcelFile(bytes);
      
      // Предпросмотр данных
      final previewData = ExcelEstimateService.preparePreview(bytes);
      
      setState(() {
        _validationResult = validationResult;
        _previewData = previewData;
        _showPreview = true;
        _validationPassed = validationResult.isValid;
        _totalRows = previewData.rowCount;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationsService.showErrorNotification(
        context, 
        'Ошибка при обработке файла: $e'
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  
  /// Импортирует данные из Excel в таблицу смет
  Future<void> _importExcelData() async {
    if (!formKey.currentState!.validate() || pickedFile?.bytes == null) return;
    if (!_validationPassed && _validationResult != null && _validationResult!.errors.isNotEmpty) {
      NotificationsService.showErrorNotification(
        context, 
        'Невозможно импортировать файл с ошибками структуры'
      );
      return;
    }
    
    final userId = widget.ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      NotificationsService.showErrorNotification(
        context, 
        'Не удалось определить пользователя'
      );
      return;
    }
    
    // Определяем, импортируем ли мы в существующую смету
    final estimateTitle = _estimateNameController.text.trim();
    final isExistingEstimate = _filteredEstimateTitles.contains(estimateTitle);
    
    setState(() {
      _isImporting = true;
      _importedRows = 0;
      _importStatus = isExistingEstimate 
          ? 'Добавление позиций в существующую смету...'
          : 'Начало импорта новой сметы...';
    });
    
    try {
      final bytes = Uint8List.fromList(pickedFile!.bytes!);
      final excelFile = excel.Excel.decodeBytes(bytes);
      final sheet = excelFile.tables[excelFile.tables.keys.first]!;
      final rows = sheet.rows.skip(1).toList(); // пропускаем заголовки
      final estimateRepo = widget.ref.read(estimateRepositoryProvider);
      
      _totalRows = rows.length;
      int successCount = 0;
      
      for (int i = 0; i < rows.length; i++) {
        if (!mounted) break;
        
        try {
          setState(() {
            _importedRows = i;
            _importStatus = 'Импорт строки ${i+1} из $_totalRows...';
          });
          
          final row = rows[i];
          final modelData = ExcelEstimateService.rowToEstimateModel(
            row, 
            selectedObjectId, 
            selectedContractId, 
            estimateTitle,
          );
          
          if (modelData != null) {
            final model = EstimateModel(
              system: modelData['system'],
              subsystem: modelData['subsystem'],
              number: modelData['number'],
              name: modelData['name'],
              article: modelData['article'],
              manufacturer: modelData['manufacturer'],
              unit: modelData['unit'],
              quantity: modelData['quantity'],
              price: modelData['price'],
              total: modelData['total'],
              objectId: modelData['objectId'],
              contractId: modelData['contractId'],
              estimateTitle: modelData['estimateTitle'],
            );
            
            await estimateRepo.createEstimate(model.toDomain());
            successCount++;
          }
        } catch (rowError) {
          // Логируем ошибку, но продолжаем импорт
          debugPrint('Ошибка импорта строки ${i+1}: $rowError');
        }
      }
      
      // Сохраняем файл в хранилище Supabase
      setState(() => _importStatus = 'Сохранение файла...');
      
      final supabase = widget.ref.read(supabaseClientProvider);
      final fileName = 'estimate_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      await supabase.storage.from('estimates').uploadBinary(fileName, bytes);
      
      // Финальное сообщение в зависимости от типа операции
      final completionMessage = isExistingEstimate
          ? 'Добавлено $successCount позиций в смету "$estimateTitle"'
          : 'Создана новая смета с $successCount позициями';
      
      setState(() => _importStatus = 'Импорт завершен успешно!');
      widget.onSuccess();
      
      if (!mounted) return;
      NotificationsService.showSuccessNotification(context, completionMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _importStatus = 'Ошибка импорта: $e');
      NotificationsService.showErrorNotification(context, 'Ошибка импорта: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
  
  /// Строит шаги интерфейса импорта
  Widget _buildStepper() {
    return Stepper(
      currentStep: _currentStep,
      controlsBuilder: (context, details) {
        // Определяем, можно ли продолжить для текущего шага
        bool canContinue = true;
        
        // Для первого шага проверяем валидность файла
        if (_currentStep == 0) {
          canContinue = pickedFile != null && _validationPassed && _validationResult != null && _validationResult!.isValid;
        }
        
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
              children: [
              if (_currentStep < 2)
                ElevatedButton(
                  onPressed: canContinue ? details.onStepContinue : null,
                  child: Text(_currentStep == 1 ? 'Импортировать' : 'Продолжить'),
                ),
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Назад'),
                  ),
                ),
            ],
          ),
        );
      },
      onStepContinue: () {
        if (_currentStep == 0) {
          if (pickedFile == null) {
            NotificationsService.showInfoNotification(
              context, 
              'Выберите файл для импорта'
            );
            return;
          }
          
          // Проверяем, прошел ли файл валидацию
          if (!_validationPassed || _validationResult == null || !_validationResult!.isValid) {
            NotificationsService.showErrorNotification(
              context, 
              'Файл содержит ошибки и не может быть импортирован'
            );
            return;
          }
          
          // Если проверка пройдена, переходим к следующему шагу
          setState(() => _currentStep = 1);
        } else if (_currentStep == 1) {
          if (!formKey.currentState!.validate()) {
            return;
          }
          estimateName = _estimateNameController.text.trim();
          setState(() => _currentStep = 2);
          _importExcelData();
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      onStepTapped: (index) {
        // Запрещаем тап на шаг 1, если файл не прошел валидацию
        if (index == 1 && (!_validationPassed || _validationResult == null || !_validationResult!.isValid)) {
          NotificationsService.showInfoNotification(
            context, 
            'Сначала загрузите корректный Excel-файл'
          );
          return;
        }
        
        // Разрешаем переходить назад или на доступные шаги
        if (!_isImporting && index <= _currentStep) {
          setState(() => _currentStep = index);
        }
      },
      steps: [
        Step(
          title: const Text('Выберите файл'),
          subtitle: pickedFile != null 
              ? Text('Файл: ${pickedFile!.name}')
              : const Text('Выберите Excel-файл со сметой'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                    children: [
                      Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(pickedFile == null 
                          ? 'Выбрать файл Excel' 
                          : 'Изменить файл'),
                      onPressed: isLoading ? null : _pickExcelFile,
                        ),
                      ),
                  const SizedBox(width: 16),
                      IconButton(
                    tooltip: 'Скачать шаблон Excel',
                    icon: const Icon(Icons.download),
                    onPressed: isLoading ? null : _downloadTemplate,
                      ),
                    ],
                  ),
              
              // Добавляем сообщение-подсказку о статусе файла
              if (_showPreview && _validationResult != null) ...[
                const SizedBox(height: 8),
                if (!_validationResult!.isValid)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Для продолжения необходимо исправить ошибки в файле',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Файл прошел проверку. Нажмите "Продолжить" для перехода к следующему шагу.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                
                const SizedBox(height: 8),
                if (_validationResult!.errors.isNotEmpty) ...[
                  const Text(
                    'Ошибки в файле:',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  ...buildErrorsList(_validationResult!.errors),
                ],
                if (_validationResult!.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Предупреждения:',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  ...buildErrorsList(_validationResult!.warnings),
                ],
                if (_validationResult!.isValid) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Файл прошел проверку',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  Text('Строк данных: ${_previewData?.rowCount ?? 0}'),
                  Text('Валидных строк: ${_previewData?.validRowCount ?? 0}'),
                  Text('Общая сумма: ${moneyFormat.format(_previewData?.totalAmount ?? 0)}'),
                  
                  // Таблица предпросмотра
                  if (_previewData != null && _previewData!.rows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Предварительный просмотр данных (первые 5 строк из ${_previewData!.rowCount}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPreviewTable(),
                  ],
                ],
              ],
            ],
          ),
          isActive: _currentStep == 0,
          state: _showPreview && _validationResult != null
              ? (_validationResult!.isValid ? StepState.complete : StepState.error)
              : StepState.indexed,
        ),
        Step(
          title: const Text('Выберите параметры'),
          subtitle: Text(selectedObjectId != null && selectedContractId != null && _estimateNameController.text.isNotEmpty
              ? 'Смета: ${_estimateNameController.text}'
              : 'Укажите объект, договор и название сметы'),
          content: _buildDataForm(),
          isActive: _currentStep == 1,
          state: _validationPassed && _validationResult != null && _validationResult!.isValid 
              ? (formKey.currentState?.validate() == true ? StepState.complete : StepState.indexed)
              : StepState.disabled,
        ),
        Step(
          title: const Text('Создание сметы'),
          subtitle: _isImporting 
              ? Text('Прогресс: $_importedRows из $_totalRows')
              : const Text('Выберите существующую смету или создайте новую'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isImporting) ...[
                LinearProgressIndicator(
                  value: _totalRows > 0 ? _importedRows / _totalRows : 0,
                ),
                const SizedBox(height: 16),
                Text(_importStatus),
              ] else ...[
                Text(_importStatus.isEmpty 
                  ? 'Нажмите кнопку "Импортировать" для начала импорта'
                  : _importStatus),
              ],
            ],
          ),
          isActive: _currentStep == 2,
          state: _isImporting ? StepState.editing : StepState.indexed,
        ),
      ],
    );
  }
  
  /// Строит список ошибок/предупреждений
  List<Widget> buildErrorsList(List<String> messages) {
    return messages.map((message) => Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(message)),
        ],
      ),
    )).toList();
  }
  
  /// Строит форму с полями выбора объекта, договора и названия сметы
  Widget _buildDataForm() {
    final objectState = widget.ref.watch(objectProvider);
    final contractState = widget.ref.watch(contractProvider);
    
    return Form(
      key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TypeAheadField для объекта
                        TypeAheadField<String>(
                          controller: _objectController,
                          suggestionsCallback: (pattern) {
                            return objectState.objects
                              .where((o) => o.name.toLowerCase().contains(pattern.toLowerCase()))
                              .map((o) => o.name)
                              .toList();
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(title: Text(suggestion));
                          },
                          onSelected: (suggestion) {
                            final obj = objectState.objects.firstWhere((o) => o.name == suggestion);
                            setState(() {
                // Если изменился объект, сбрасываем выбранный договор
                if (selectedObjectId != obj.id) {
                  _resetContractSelection();
                }
                              selectedObjectId = obj.id;
                              _objectController.text = obj.name;
                            });
              
              // После выбора объекта обновляем списки договоров и смет
              _filterEstimates();
                          },
                          emptyBuilder: (context) => const ListTile(title: Text('Нет совпадений')), 
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Объект *',
                                hintText: 'Выберите объект',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => selectedObjectId == null ? 'Выберите объект' : null,
                              readOnly: false,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // TypeAheadField для договора
                        TypeAheadField<String>(
                          controller: _contractController,
                          suggestionsCallback: (pattern) {
              return _getFilteredContracts(pattern);
                          },
                          itemBuilder: (context, suggestion) {
              final contract = contractState.contracts.firstWhere(
                (c) => c.number == suggestion,
                orElse: () => contractState.contracts.first,
              );
              return ListTile(
                title: Text(suggestion),
                subtitle: Text(contract.contractorName ?? "Без контрагента"),
              );
                          },
                          onSelected: (suggestion) {
                            final contract = contractState.contracts.firstWhere((c) => c.number == suggestion);
                            setState(() {
                              selectedContractId = contract.id;
                              _contractController.text = contract.number;
                            });
              
              // После выбора договора обновляем список смет
              _filterEstimates();
            },
            emptyBuilder: (context) {
              if (selectedObjectId == null) {
                return const ListTile(
                  title: Text('Сначала выберите объект'),
                  leading: Icon(Icons.info_outline),
                );
              }
              return const ListTile(title: Text('Нет договоров для выбранного объекта'));
            }, 
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                decoration: InputDecoration(
                                labelText: 'Договор *',
                  hintText: selectedObjectId == null 
                      ? 'Сначала выберите объект' 
                      : 'Выберите договор',
                  border: const OutlineInputBorder(),
                  enabled: selectedObjectId != null,
                              ),
                              validator: (v) => selectedContractId == null ? 'Выберите договор' : null,
                              readOnly: false,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
          // TypeAheadField для названия сметы
          TypeAheadField<String>(
            controller: _estimateNameController,
            suggestionsCallback: (pattern) {
              if (_loadingEstimateTitles) return [];
              
              return _filteredEstimateTitles
                  .where((title) => title.toLowerCase().contains(pattern.toLowerCase()))
                  .toList();
            },
            itemBuilder: (context, suggestion) {
              final estimates = widget.ref.read(estimateNotifierProvider).estimates;
              final count = estimates.where((e) => 
                  e.estimateTitle == suggestion && 
                  (selectedObjectId == null || e.objectId == selectedObjectId) &&
                  (selectedContractId == null || e.contractId == selectedContractId)
              ).length;
              
              return ListTile(
                title: Text(suggestion),
                subtitle: Text('$count позиций в смете'),
                leading: const Icon(Icons.article_outlined),
              );
            },
            onSelected: (suggestion) {
              setState(() {
                _estimateNameController.text = suggestion;
              });
              
              // Обновляем информацию об объекте и договоре на основе выбранной сметы
              _updateEstimateInfo(suggestion);
            },
            emptyBuilder: (context) {
              final input = _estimateNameController.text.trim();
              if (input.isEmpty) return const SizedBox();
              
              if (selectedObjectId == null || selectedContractId == null) {
                return const ListTile(
                  title: Text('Сначала выберите объект и договор'),
                  leading: Icon(Icons.info_outline),
                );
              }
              
              return ListTile(
                title: Text('Создать новую смету "$input"'),
                leading: const Icon(Icons.add_circle_outline),
                onTap: () {
                  setState(() {
                    _estimateNameController.text = input;
                  });
                  context.pop();
                },
              );
            },
            builder: (context, controller, focusNode) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Название сметы *',
                  hintText: selectedObjectId == null || selectedContractId == null
                      ? 'Сначала выберите объект и договор'
                      : 'Выберите существующую смету или введите новую',
                  border: const OutlineInputBorder(),
                  helperText: _filteredEstimateTitles.isEmpty
                      ? 'Нет смет для выбранной комбинации объект/договор'
                      : '${_filteredEstimateTitles.length} смет для выбранных параметров',
                  suffixIcon: _loadingEstimateTitles 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        )
                      : null,
                ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Введите название' : null,
                readOnly: false,
              );
                                },
                        ),
                      ],
                    ),
    );
  }
  
  /// Строит таблицу предпросмотра данных из Excel
  Widget _buildPreviewTable() {
    if (_previewData == null || _previewData!.rows.isEmpty) {
      return const SizedBox();
    }
    
    // Функция для корректного форматирования значения ячейки
    String formatCellValue(dynamic cell) {
      if (cell == null) return '';
      
      // Извлекаем значение из ячейки excel.Data
      final value = cell is excel.Data ? cell.value : cell;
      
      if (value == null) return '';
      
      // Форматируем в зависимости от типа данных
      if (value is num) {
        // Форматируем числа с десятичной точкой, если нужно
        if (value == value.truncate()) {
          return value.toInt().toString();
        } else {
          return value.toString();
        }
      }
      
      return value.toString();
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _previewData!.rows.first
          .take(7) // Ограничиваем количество столбцов для упрощения вида
          .map((cell) => DataColumn(
            label: Text(
              formatCellValue(cell),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ))
          .toList(),
        rows: _previewData!.rows.length > 1
          ? _previewData!.rows.skip(1).take(5) // Берем только 5 строк для предпросмотра
              .map((row) => DataRow(
                cells: row.take(7)
                  .map((cell) => DataCell(
                    Text(formatCellValue(cell))
                  ))
                  .toList(),
              ))
              .toList()
          : [],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок и кнопка закрытия
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Импорт сметы из Excel',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Основное содержимое с шагами
              isLoading && !_isImporting
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStepper(),
              ],
          ),
        ),
      ),
    );
  }
} 