import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pluto_grid/pluto_grid.dart'; // подключить при наличии
import '../../../../core/di/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:excel/excel.dart' as excel;
import 'package:excel/excel.dart' show TextCellValue, DoubleCellValue;
import 'dart:typed_data';
import 'import_estimate_form_modal.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import '../../../../domain/entities/estimate.dart';
import 'dart:io';

/// Экран со списком всех смет.
///
/// Позволяет просматривать, фильтровать, импортировать и экспортировать сметы.
class EstimatesListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка смет.
  const EstimatesListScreen({super.key});

  @override
  ConsumerState<EstimatesListScreen> createState() => _EstimatesListScreenState();
}

/// Состояние для [EstimatesListScreen].
class _EstimatesListScreenState extends ConsumerState<EstimatesListScreen> {
  /// Список строк из Excel-файла для предпросмотра.
  List<List<excel.Data?>>? _excelRows;

  /// Имя импортированного Excel-файла.
  String? _excelFileName;

  /// Форматтер для отображения денежных значений.
  final NumberFormat moneyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '',
    decimalDigits: 2,
  );

  /// Форматирует денежное значение [value] в строку.
  String formatMoney(double value) {
    return moneyFormat.format(value).trim();
  }

  /// Название сметы для фильтрации или отображения.
  final String estimateTitle = '';

  /// Список всех смет, полученных из состояния.
  List<Estimate> get estimates => ref.watch(estimateNotifierProvider).estimates;

  /// Текущая выбранная смета.
  Estimate? get selectedEstimate => ref.watch(estimateNotifierProvider).selectedEstimate;

  /// Флаг загрузки данных.
  bool get isLoading => ref.watch(estimateNotifierProvider).isLoading;

  /// Сообщение об ошибке, если есть.
  String? get error => ref.watch(estimateNotifierProvider).error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(estimateNotifierProvider.notifier).loadEstimates();
    });
  }

  void _showImportEstimateBottomSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
      ),
      builder: (context) {
        Widget modalContent = Container(
          margin: isDesktop ? const EdgeInsets.only(top: 48) : null,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ImportEstimateFormModal(
                    ref: ref,
                    onSuccess: () async {
                      if (context.mounted) context.pop();
                      SnackBarUtils.showSuccess(context, 'Смета успешно импортирована');
                    },
                    onCancel: () => context.pop(),
                  ),
                ),
              ),
            ),
          ),
        );
        if (isDesktop) {
          return Center(
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 220),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                    ),
                    child: modalContent,
                  ),
                ),
              ),
            ),
          );
        } else {
          return modalContent;
        }
      },
    );
  }

  /// Экспортирует список смет в Excel-файл
  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final estimates = ref.read(estimateNotifierProvider).estimates;
      if (estimates.isEmpty) {
        SnackBarUtils.showInfo(context, 'Нет данных для экспорта');
        return;
      }
      
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Сметы'];
      
      // Добавляем заголовки
      sheet.appendRow([
        TextCellValue('Система'),
        TextCellValue('Подсистема'),
        TextCellValue('№'),
        TextCellValue('Наименование'),
        TextCellValue('Артикул'),
        TextCellValue('Производитель'),
        TextCellValue('Ед. изм.'),
        TextCellValue('Кол-во'),
        TextCellValue('Цена'),
        TextCellValue('Сумма'),
        TextCellValue('Объект'),
        TextCellValue('Договор'),
        TextCellValue('Название сметы'),
      ]);
      
      // Получаем списки объектов и договоров
      final objects = ref.read(objectProvider).objects;
      final contracts = ref.read(contractProvider).contracts;
      
      // Добавляем данные
      for (final estimate in estimates) {
        // Находим имя объекта
        String objectName = '';
        if (estimate.objectId != null) {
          final objectEntity = objects.firstWhereOrNull((o) => o.id == estimate.objectId);
          if (objectEntity != null) {
            objectName = objectEntity.name;
          }
        }
            
        // Находим номер договора
        String contractNumber = '';
        if (estimate.contractId != null) {
          final contractEntity = contracts.firstWhereOrNull((c) => c.id == estimate.contractId);
          if (contractEntity != null) {
            contractNumber = contractEntity.number;
          }
        }
            
        sheet.appendRow([
          TextCellValue(estimate.system),
          TextCellValue(estimate.subsystem),
          TextCellValue(estimate.number),
          TextCellValue(estimate.name),
          TextCellValue(estimate.article),
          TextCellValue(estimate.manufacturer),
          TextCellValue(estimate.unit),
          DoubleCellValue(estimate.quantity),
          DoubleCellValue(estimate.price),
          DoubleCellValue(estimate.total),
          TextCellValue(objectName),
          TextCellValue(contractNumber),
          TextCellValue(estimate.estimateTitle ?? ''),
        ]);
      }
      
      final bytes = excelFile.encode()!;
      final fileName = 'estimates_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        final directory = await path_provider.getTemporaryDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([XFile(path)], text: 'Экспорт смет');
      }
      
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, 'Сметы экспортированы в Excel');
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, 'Ошибка экспорта: $e');
    }
  }

  /// Удаляет всю смету и все её позиции
  void _deleteEstimateFile(EstimateFile file) async {
    final notifier = ref.read(estimateNotifierProvider.notifier);
    
    // Удаляем все позиции сметы
    for (final item in file.items) {
      await notifier.deleteEstimate(item.id);
    }
    
    // Обновляем список смет
    await notifier.loadEstimates();
    
    // Показываем уведомление
    if (!mounted) return;
    SnackBarUtils.showSuccess(
      context, 
      'Смета "${file.estimateTitle}" удалена'
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimateNotifierProvider);
    final contracts = ref.watch(contractProvider).contracts;
    final objects = ref.watch(objectProvider).objects;
    final estimateFiles = groupEstimatesByFile(state.estimates);
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Сметы',
        actions: [
          // Кнопка экспорта Excel
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Экспортировать Excel',
            onPressed: () => _exportToExcel(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить данные',
            onPressed: () => ref.read(estimateNotifierProvider.notifier).loadEstimates(),
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.estimates),
      body: _excelRows != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_excelFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('Файл: $_excelFileName', style: Theme.of(context).textTheme.titleMedium),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: _excelRows!.first
                            .map((cell) => DataColumn(label: Text((cell)?.value?.toString() ?? '')))
                            .toList(),
                        rows: _excelRows!.skip(1)
                            .map((row) => DataRow(
                                  cells: row
                                      .map((cell) => DataCell(Text((cell)?.value?.toString() ?? '')))
                                      .toList(),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Ошибка: ${state.error}'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: estimateFiles.length,
                            itemBuilder: (context, index) {
                              final file = estimateFiles[index];
                              final contract = contracts.firstWhereOrNull((c) => c.id == file.contractId);
                              final object = objects.firstWhereOrNull((o) => o.id == file.objectId);
                              final contractNumber = contract?.number ?? '—';
                              final objectName = object?.name ?? '—';
                              return Dismissible(
                                key: Key(file.estimateTitle),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await CupertinoDialogs.showDeleteConfirmDialog<bool>(
                                    context: context, 
                                    title: 'Удаление сметы',
                                    message: 'Вы действительно хотите удалить смету "${file.estimateTitle}" и все её позиции?',
                                    onConfirm: () {
                                      _deleteEstimateFile(file);
                                    },
                                    onCancel: () {
                                    },
                                  );
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => context.go('/estimates/${Uri.encodeComponent(file.estimateTitle)}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  file.estimateTitle,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const AppBadge(
                                                text: 'Загружена',
                                                color: Colors.green,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Договор: $contractNumber', style: Theme.of(context).textTheme.bodyMedium),
                                          Text('Объект: $objectName', style: Theme.of(context).textTheme.bodyMedium),
                                          Text('Позиций: ${file.items.length}', style: Theme.of(context).textTheme.bodyMedium),
                                          Text('Сумма: ${formatMoney(file.total)}', style: Theme.of(context).textTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportEstimateBottomSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Группировка позиций сметы по файлу (названию, объекту, договору).
class EstimateFile {
  /// Название сметы (файла).
  final String estimateTitle;

  /// Идентификатор объекта.
  final String? objectId;

  /// Идентификатор договора.
  final String? contractId;

  /// Список позиций сметы, входящих в файл.
  final List<Estimate> items;

  /// Создаёт экземпляр [EstimateFile].
  const EstimateFile({
    required this.estimateTitle,
    required this.objectId,
    required this.contractId,
    required this.items,
  });

  /// Общая сумма по всем позициям файла.
  double get total => items.fold(0, (sum, e) => sum + e.total);
}

/// Группирует список смет [estimates] по названию, объекту и договору.
///
/// Возвращает список [EstimateFile] для отображения в UI.
List<EstimateFile> groupEstimatesByFile(List<Estimate> estimates) {
  final grouped = groupBy(
    estimates,
    (Estimate e) => '${e.estimateTitle}_${e.objectId}_${e.contractId}',
  );
  return grouped.entries.map((entry) {
    final first = entry.value.first;
    return EstimateFile(
      estimateTitle: first.estimateTitle ?? 'Без названия',
      objectId: first.objectId,
      contractId: first.contractId,
      items: entry.value,
    );
  }).toList();
} 