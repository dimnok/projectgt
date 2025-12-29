import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart' as excel;
import 'package:excel/excel.dart' show TextCellValue, DoubleCellValue;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimate_details_screen.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/screens/import_estimate_form_modal.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:share_plus/share_plus.dart';

/// Экран со списком всех смет.
class EstimatesListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран со списком смет.
  const EstimatesListScreen({super.key});

  @override
  ConsumerState<EstimatesListScreen> createState() =>
      _EstimatesListScreenState();
}

class _EstimatesListScreenState extends ConsumerState<EstimatesListScreen> {
  EstimateFile? selectedEstimateFile;

  @override
  void initState() {
    super.initState();
    // Данные загружаются через FutureProvider, явный вызов не нужен
  }

  void _showImportEstimateBottomSheet(BuildContext context) {
    ImportEstimateFormModal.show(
      context,
      ref,
      onSuccess: () async {
        if (context.mounted) context.pop();
        SnackBarUtils.showSuccess(context, 'Смета успешно импортирована');
        ref.invalidate(estimateGroupsProvider);
      },
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Загружаем все группы смет
      final groups = await ref.read(estimateGroupsProvider.future);
      if (!context.mounted) return;
      if (groups.isEmpty) {
        SnackBarUtils.showInfo(context, 'Нет данных для экспорта');
        return;
      }

      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Сметы'];

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
        TextCellValue('ID'),
      ]);

      final objects = ref.read(objectProvider).objects;

      // Проходим по каждой группе и загружаем её элементы для экспорта
      for (final group in groups) {
        // Загружаем элементы для каждой группы
        final items = await ref.read(estimateItemsProvider(EstimateDetailArgs(
          estimateTitle: group.estimateTitle,
          objectId: group.objectId,
          contractId: group.contractId,
        )).future);

        String objectName = '';
        if (group.objectId != null) {
          final objectEntity =
              objects.firstWhereOrNull((o) => o.id == group.objectId);
          if (objectEntity != null) {
            objectName = objectEntity.name;
          }
        }

        final contractNumber = group.contractNumber ?? '—';

        for (final estimate in items) {
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
            TextCellValue(estimate.contractNumber ?? contractNumber),
            TextCellValue(group.estimateTitle),
            TextCellValue(estimate.id),
          ]);
        }
      }

      final bytes = excelFile.encode()!;
      final fileName =
          'estimates_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Экспорт смет',
          ),
        );
      }

      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, 'Сметы экспортированы в Excel');
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, 'Ошибка экспорта: $e');
    }
  }

  void _deleteEstimateFile(EstimateFile file) async {
    final notifier = ref.read(estimateNotifierProvider.notifier);

    // Сначала загружаем элементы, чтобы узнать их ID для удаления
    try {
      final items = await ref.read(estimateItemsProvider(EstimateDetailArgs(
        estimateTitle: file.estimateTitle,
        objectId: file.objectId,
        contractId: file.contractId,
      )).future);

      for (final item in items) {
        await notifier.deleteEstimate(item.id);
      }

      ref.invalidate(estimateGroupsProvider);

      if (!mounted) return;
      if (selectedEstimateFile?.estimateTitle == file.estimateTitle) {
        setState(() {
          selectedEstimateFile = null;
        });
      }

      SnackBarUtils.showSuccess(
          context, 'Смета "${file.estimateTitle}" удалена');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка удаления: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(estimateGroupsProvider);
    final objects = ref.watch(objectProvider).objects;
    final permissionService = ref.watch(permissionServiceProvider);
    final canDelete = permissionService.can('estimates', 'delete');
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Сметы',
        actions: [
          PermissionGuard(
            module: 'estimates',
            permission: 'export',
            child: IconButton(
              icon: const Icon(CupertinoIcons.arrow_down_doc),
              tooltip: 'Экспортировать Excel',
              onPressed: () => _exportToExcel(context),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            tooltip: 'Обновить данные',
            onPressed: () {
              ref.invalidate(estimateGroupsProvider);
              ref.invalidate(estimateItemsProvider);
              ref.invalidate(estimateCompletionByIdsProvider);
            },
          ),
          if (!ResponsiveUtils.isDesktop(context))
            PermissionGuard(
              module: 'estimates',
              permission: 'import',
              child: IconButton(
                icon: const Icon(CupertinoIcons.add),
                onPressed: () => _showImportEstimateBottomSheet(context),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.estimates),
      body: groupsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, s) => Center(child: Text('Ошибка: $e')),
        data: (estimateFiles) {
          // Если выбранная смета исчезла (удалена), сбрасываем выбор
          if (selectedEstimateFile != null &&
              !estimateFiles.any((f) =>
                  f.estimateTitle == selectedEstimateFile!.estimateTitle &&
                  f.objectId == selectedEstimateFile!.objectId &&
                  f.contractId == selectedEstimateFile!.contractId)) {
            // Используем addPostFrameCallback, чтобы избежать ошибки во время build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  selectedEstimateFile = null;
                });
              }
            });
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (isDesktop) {
                return const EstimateDetailsScreen(showAppBar: false);
              } else {
                return _buildMobileLayout(
                  estimateFiles,
                  objects,
                  canDelete,
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    List<EstimateFile> estimateFiles,
    List<ObjectEntity> objects,
    bool canDelete,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: estimateFiles.length,
      itemBuilder: (context, index) {
        final file = estimateFiles[index];
        return _buildEstimateCard(
          file: file,
          objects: objects,
          canDelete: canDelete,
          isSelected: false,
          onTap: () => context.go(
            '/estimates/${Uri.encodeComponent(file.estimateTitle)}',
          ),
        );
      },
    );
  }

  Widget _buildEstimateCard({
    required EstimateFile file,
    required List<ObjectEntity> objects,
    required bool canDelete,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Номер договора теперь берем напрямую из файла (через View)
    final contractNumber = file.contractNumber ?? '—';
    final object = objects.firstWhereOrNull((o) => o.id == file.objectId);
    final objectName = object?.name ?? '—';
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(
          '${file.estimateTitle}_${file.objectId ?? "null"}_${file.contractId ?? "null"}'),
      direction:
          canDelete ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (direction) async {
        return await CupertinoDialogs.showDeleteConfirmDialog<bool>(
          context: context,
          title: 'Удаление сметы',
          message:
              'Вы действительно хотите удалить смету "${file.estimateTitle}" и все её позиции?',
          onConfirm: () {
            _deleteEstimateFile(file);
          },
          onCancel: () {},
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          CupertinoIcons.trash,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: isSelected ? 2 : 0,
        color: isSelected ? theme.colorScheme.surfaceContainerHighest : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
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
                const SizedBox(height: 8),
                _buildInfoRow(theme, 'Договор:', contractNumber),
                const SizedBox(height: 4),
                _buildInfoRow(theme, 'Объект:', objectName),
                const SizedBox(height: 4),
                _buildInfoRow(theme, 'Сумма:', formatCurrency(file.total)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Класс EstimateFile и функция groupEstimatesByFile удалены,
// так как они теперь определены в estimate_providers.dart (класс EstimateFile)
// и группировка происходит на сервере.
