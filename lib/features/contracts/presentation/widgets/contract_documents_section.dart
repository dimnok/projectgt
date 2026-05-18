import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_file_download_flow.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_file_edit_dialog.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_document_status_chip.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_files_bulk_status_dialog.dart';

/// Раздел «Документы» договора.
///
/// Отображает список файлов с названиями и описаниями.
/// Позволяет загружать новые файлы (PDF, Word, Excel и др.) с указанием метаданных.
/// Режим упорядочивания и сохранение порядка — из панели быстрых действий (десктоп);
/// над списком в режиме перестановки показывается только подсказка. Переключатель
/// примечаний к файлам — в быстрых действиях (широкая вёрстка) или в шапке карточки
/// (узкая вёрстка).
/// Пока список пуст и идёт загрузка, показывается строка-заглушка с индикатором.
class ContractDocumentsSection extends ConsumerStatefulWidget {
  /// Договор, к которому относятся документы.
  final Contract contract;

  /// Показать подпись блока над списком (в полной карточке договора без дубля toolbar).
  final bool showSectionHeader;

  /// Создает раздел документов договора.
  const ContractDocumentsSection({
    super.key,
    required this.contract,
    this.showSectionHeader = true,
  });

  @override
  ConsumerState<ContractDocumentsSection> createState() =>
      _ContractDocumentsSectionState();
}

class _ContractDocumentsSectionState
    extends ConsumerState<ContractDocumentsSection> {
  List<ContractFile>? _reorderDraft;

  /// Выбранные для массовых операций файлы (только вне режима упорядочивания).
  final Set<String> _selectedFileIds = {};

  Future<void> _handleEdit(BuildContext context, ContractFile file) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final saved = await ContractFileEditDialog.show(
        context: context,
        contractId: widget.contract.id,
        file: file,
      );
      if (!context.mounted) return;
      if (saved == true) {
        AppSnackBar.show(
          context: context,
          message: 'Изменения сохранены',
          kind: AppSnackBarKind.success,
        );
      }
    });
  }

  Future<void> _handleDelete(BuildContext context, ContractFile file) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final confirmed = await GTConfirmationDialog.show(
        context: context,
        title: 'Удаление документа',
        message:
            'Документ будет удалён из списка и из хранилища без возможности восстановления. Продолжить?',
        emphasisText: file.name,
        detail: file.description,
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        type: GTConfirmationType.danger,
      );

      if (confirmed == true) {
        try {
          await ref
              .read(contractFilesProvider(widget.contract.id).notifier)
              .deleteFile(file.id, file.filePath);
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Документ удален',
            kind: AppSnackBarKind.success,
          );
        } catch (e) {
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Ошибка при удалении: $e',
            kind: AppSnackBarKind.error,
          );
        }
      }
    });
  }

  void _exitReorderMode() {
    ref
            .read(
              contractDocumentsReorderModeProvider(widget.contract.id).notifier,
            )
            .state =
        false;
  }

  Future<void> _saveReorder(BuildContext context) async {
    final draft = _reorderDraft;
    if (draft == null) return;
    try {
      await ref
          .read(contractFilesProvider(widget.contract.id).notifier)
          .saveFilesDisplayOrder(draft.map((e) => e.id).toList());
      _exitReorderMode();
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Порядок сохранён',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить порядок: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  void _pruneSelectionToExisting(List<ContractFile> files) {
    final valid = files.map((e) => e.id).toSet();
    final next = _selectedFileIds.intersection(valid);
    if (next.length != _selectedFileIds.length) {
      setState(() {
        _selectedFileIds
          ..clear()
          ..addAll(next);
      });
    }
  }

  Future<void> _bulkDownloadSelected(
    BuildContext context,
    List<ContractFile> selectedFiles,
  ) async {
    for (final f in selectedFiles) {
      if (!context.mounted) return;
      await downloadContractFileForUser(
        context: context,
        ref: ref,
        contractId: widget.contract.id,
        file: f,
      );
    }
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: selectedFiles.length == 1
          ? 'Файл отправлен на скачивание'
          : 'Запрошено скачивание файлов: ${selectedFiles.length}',
      kind: AppSnackBarKind.success,
    );
  }

  Future<void> _bulkDeleteSelected(
    BuildContext context,
    List<ContractFile> selectedFiles,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удаление документов',
      message:
          'Будет удалено документов: ${selectedFiles.length}. Файлы исчезнут из списка и из хранилища без восстановления. Продолжить?',
      emphasisText: '${selectedFiles.length} шт.',
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(contractFilesProvider(widget.contract.id).notifier)
          .bulkDeleteFiles(selectedFiles);
      if (!context.mounted) return;
      setState(() => _selectedFileIds.clear());
      AppSnackBar.show(
        context: context,
        message: 'Документы удалены',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Ошибка при удалении: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _bulkChangeStatus(
    BuildContext context,
    List<String> fileIds,
  ) async {
    final ok = await ContractFilesBulkStatusDialog.show(
      context: context,
      contractId: widget.contract.id,
      fileIds: fileIds,
    );
    if (!context.mounted) return;
    if (ok == true) {
      setState(() => _selectedFileIds.clear());
      AppSnackBar.show(
        context: context,
        message: 'Статус обновлён',
        kind: AppSnackBarKind.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(contractFilesProvider(widget.contract.id));
    final reorderMode = ref.watch(
      contractDocumentsReorderModeProvider(widget.contract.id),
    );
    final descriptionsVisible = ref.watch(
      contractDocumentDescriptionsVisibleProvider(widget.contract.id),
    );
    final downloadingIds = ref.watch(
      contractFileDownloadingIdsProvider(widget.contract.id),
    );

    ref.listen(contractFilesProvider(widget.contract.id), (_, next) {
      _pruneSelectionToExisting(next.files);
    });

    ref.listen(contractDocumentsReorderModeProvider(widget.contract.id), (
      _,
      enteringReorder,
    ) {
      if (enteringReorder && _selectedFileIds.isNotEmpty) {
        setState(() => _selectedFileIds.clear());
      }
    });

    ref.listen<int>(
      contractDocumentsReorderSaveRequestProvider(widget.contract.id),
      (previous, next) {
        if (previous == null || next <= previous) return;
        if (!ref.read(
          contractDocumentsReorderModeProvider(widget.contract.id),
        )) {
          return;
        }
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          await _saveReorder(context);
        });
      },
    );

    if (!reorderMode) {
      _reorderDraft = null;
    } else {
      _reorderDraft ??= List<ContractFile>.from(state.files);
    }

    final filesForList = reorderMode ? _reorderDraft! : state.files;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSectionHeader) ...[
          const GTSectionTitle(title: 'Документы договора'),
          const SizedBox(height: 20),
        ],
        if (reorderMode) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Перетащите строки за иконку слева. Сохраните порядок кнопкой «Готово» в панели быстрых действий справа.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                ),
                if (state.isLoading) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: CupertinoActivityIndicator(
                      radius: 7,
                      color: scheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!reorderMode && filesForList.isNotEmpty) ...[
          _DocumentsSelectionHeaderBar(
            allFileIds: filesForList.map((e) => e.id).toSet(),
            selectedFileIds: _selectedFileIds,
            onToggleSelectAll: (selectAll) {
              setState(() {
                if (selectAll) {
                  _selectedFileIds
                    ..clear()
                    ..addAll(filesForList.map((e) => e.id));
                } else {
                  _selectedFileIds.clear();
                }
              });
            },
            onClearSelection: () => setState(_selectedFileIds.clear),
            onDownload: () {
              final list = filesForList
                  .where((f) => _selectedFileIds.contains(f.id))
                  .toList();
              _bulkDownloadSelected(context, list);
            },
            onDelete: () {
              final list = filesForList
                  .where((f) => _selectedFileIds.contains(f.id))
                  .toList();
              _bulkDeleteSelected(context, list);
            },
            onChangeStatus: () =>
                _bulkChangeStatus(context, _selectedFileIds.toList()),
            onBindSection: () {
              if (!context.mounted) return;
              AppSnackBar.show(
                context: context,
                message: 'Привязка к разделу — в разработке',
                kind: AppSnackBarKind.info,
              );
            },
            onSend: () {
              if (!context.mounted) return;
              AppSnackBar.show(
                context: context,
                message: 'Отправка документов — в разработке',
                kind: AppSnackBarKind.info,
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (state.isLoading && filesForList.isEmpty && !reorderMode) ...[
          const _DocumentListLoadingSkeleton(),
          const SizedBox(height: 6),
        ],
        if (filesForList.isEmpty && !state.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.doc_on_doc,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Список документов пуст',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (reorderMode && filesForList.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: filesForList.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                var n = newIndex;
                if (n > oldIndex) n -= 1;
                final list = _reorderDraft!;
                final item = list.removeAt(oldIndex);
                list.insert(n, item);
              });
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return Material(
                    elevation: 6 * animation.value,
                    color: Colors.transparent,
                    shadowColor: scheme.shadow.withValues(alpha: 0.35),
                    child: child,
                  );
                },
              );
            },
            itemBuilder: (context, index) {
              final file = filesForList[index];
              return Padding(
                key: ValueKey(file.id),
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6, top: 10),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 22,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _DocumentCard(
                        file: file,
                        selection: null,
                        hideRowActions: true,
                        showDescriptions: descriptionsVisible,
                        isDownloading: downloadingIds.contains(file.id),
                        onDownload: () => downloadContractFileForUser(
                          context: context,
                          ref: ref,
                          contractId: widget.contract.id,
                          file: file,
                        ),
                        onEdit: () => _handleEdit(context, file),
                        onDelete: () => _handleDelete(context, file),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else if (!reorderMode && filesForList.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filesForList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final file = filesForList[index];
              return _DocumentCard(
                key: ValueKey(file.id),
                file: file,
                selection: _DocumentRowSelection(
                  isSelected: _selectedFileIds.contains(file.id),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      if (v) {
                        _selectedFileIds.add(file.id);
                      } else {
                        _selectedFileIds.remove(file.id);
                      }
                    });
                  },
                ),
                hideRowActions: false,
                showDescriptions: descriptionsVisible,
                isDownloading: downloadingIds.contains(file.id),
                onDownload: () => downloadContractFileForUser(
                  context: context,
                  ref: ref,
                  contractId: widget.contract.id,
                  file: file,
                ),
                onEdit: () => _handleEdit(context, file),
                onDelete: () => _handleDelete(context, file),
              );
            },
          ),
      ],
    );
  }
}

/// Панель выбора: «Выбрать все» и при выборе — счётчик, снять и массовые действия.
///
/// Вёрстка и поведение согласованы с практиками доступности (WCAG 2.5.8 минимум цели,
/// интервалы между интерактивными элементами) и плотным desktop-toolbar (ui-ux-pro).
class _DocumentsSelectionHeaderBar extends StatelessWidget {
  final Set<String> allFileIds;
  final Set<String> selectedFileIds;
  final void Function(bool selectAll) onToggleSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onChangeStatus;
  final VoidCallback onBindSection;
  final VoidCallback onSend;

  const _DocumentsSelectionHeaderBar({
    required this.allFileIds,
    required this.selectedFileIds,
    required this.onToggleSelectAll,
    required this.onClearSelection,
    required this.onDownload,
    required this.onDelete,
    required this.onChangeStatus,
    required this.onBindSection,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final total = allFileIds.length;
    final selectedOnPage = selectedFileIds.where(allFileIds.contains).length;
    final allSelected = total > 0 && selectedOnPage == total;
    final indeterminate = selectedOnPage > 0 && !allSelected;
    final hasSelection = selectedOnPage > 0;

    void onSelectAllTap() {
      if (total == 0) return;
      onToggleSelectAll(!allSelected);
    }

    final selectAllBlock = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 44,
            child: Center(
              child: Checkbox(
                semanticLabel: allSelected
                    ? 'Все документы выбраны. Снять выбор.'
                    : indeterminate
                        ? 'Выбрана часть документов. Нажмите, чтобы выбрать все.'
                        : 'Выбрать все документы в списке.',
                value: indeterminate ? null : allSelected,
                tristate: true,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
                onChanged: total == 0
                    ? null
                    : (v) {
                        if (v == null) return;
                        onToggleSelectAll(v);
                      },
              ),
            ),
          ),
          ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: total == 0 ? null : onSelectAllTap,
                hoverColor: scheme.onSurface.withValues(alpha: 0.06),
                splashColor: scheme.onSurface.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                  child: Text(
                    'Выбрать все',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final actions = <Widget>[
      GTTextButton(
        text: 'Скачать',
        fontSize: 13,
        icon: CupertinoIcons.cloud_download,
        onPressed: onDownload,
      ),
      const SizedBox(width: 12),
      PermissionGuard(
        module: 'contracts',
        permission: 'update',
        child: GTTextButton(
          text: 'Удалить',
          fontSize: 13,
          icon: CupertinoIcons.trash,
          color: scheme.error.withValues(alpha: 0.85),
          onPressed: onDelete,
        ),
      ),
      const SizedBox(width: 8),
      PermissionGuard(
        module: 'contracts',
        permission: 'update',
        child: GTTextButton(
          text: 'Статус',
          fontSize: 13,
          icon: CupertinoIcons.tag,
          onPressed: onChangeStatus,
        ),
      ),
      const SizedBox(width: 8),
      PermissionGuard(
        module: 'contracts',
        permission: 'update',
        child: GTTextButton(
          text: 'Раздел',
          fontSize: 13,
          icon: CupertinoIcons.folder,
          onPressed: onBindSection,
        ),
      ),
      const SizedBox(width: 8),
      PermissionGuard(
        module: 'contracts',
        permission: 'update',
        child: GTTextButton(
          text: 'Отправить',
          fontSize: 13,
          icon: CupertinoIcons.paperplane,
          onPressed: onSend,
        ),
      ),
    ];

    final selectionMeta = Semantics(
      label:
          'Выбрано документов: $selectedOnPage. Кнопка «Снять» снимает выделение.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(
              'Выбрано: $selectedOnPage',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Снять выделение со всех строк',
            child: GTTextButton(
              text: 'Снять',
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.5),
              onPressed: onClearSelection,
            ),
          ),
        ],
      ),
    );

    Widget wideSelectionTrailing() {
      return Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VerticalDivider(
                width: 24,
                thickness: 1,
                indent: 8,
                endIndent: 8,
                color: scheme.outline.withValues(alpha: 0.22),
              ),
              selectionMeta,
              const SizedBox(width: 8),
              ...actions,
            ],
          ),
        ),
      );
    }

    final barChild = LayoutBuilder(
      builder: (context, constraints) {
        final oneLine = constraints.maxWidth >= 720;
        if (!hasSelection) {
          return selectAllBlock;
        }
        if (oneLine) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              selectAllBlock,
              const SizedBox(width: 16),
              Expanded(child: wideSelectionTrailing()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            selectAllBlock,
            const SizedBox(height: 12),
            selectionMeta,
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      label: hasSelection
          ? 'Панель выбора. Выбрано $selectedOnPage из $total. Доступны массовые действия.'
          : 'Панель выбора. В списке $total документов. Отметьте строки или выберите все.',
      child: AnimatedContainer(
        width: double.infinity,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasSelection
              ? scheme.surfaceContainerLow.withValues(alpha: 0.55)
              : scheme.surfaceContainerLow.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: barChild,
      ),
    );
  }
}

/// Состояние чекбокса в строке документа.
class _DocumentRowSelection {
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _DocumentRowSelection({
    required this.isSelected,
    required this.onChanged,
  });
}

/// Плейсхолдер строки списка на время начальной загрузки файлов.
class _DocumentListLoadingSkeleton extends StatelessWidget {
  const _DocumentListLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.onSurface.withValues(alpha: 0.08);
    final bar = scheme.onSurface.withValues(alpha: 0.16);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, color: track),
              Container(width: 48, color: track),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 13,
                              width: 200,
                              decoration: BoxDecoration(
                                color: bar,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: 132,
                              decoration: BoxDecoration(
                                color: bar.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 6),
                        child: CupertinoActivityIndicator(
                          radius: 9,
                          color: scheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.cloud_download,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.22),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      CupertinoIcons.pencil,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.22),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      CupertinoIcons.trash,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  static const Color _wordIconColor = Color(0xFF2B579A);
  static const Color _excelIconColor = Color(0xFF217346);
  static const Color _pdfIconColor = Color(0xFFE53935);

  final ContractFile file;
  final _DocumentRowSelection? selection;
  final bool hideRowActions;
  final bool showDescriptions;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentCard({
    super.key,
    required this.file,
    this.selection,
    this.hideRowActions = false,
    this.showDescriptions = false,
    this.isDownloading = false,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });

  static IconData getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_rows_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color getFileIconColor(String fileName, ColorScheme colorScheme) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return _pdfIconColor;
      case 'doc':
      case 'docx':
        return _wordIconColor;
      case 'xls':
      case 'xlsx':
        return _excelIconColor;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return colorScheme.primary.withValues(alpha: 0.75);
      default:
        return colorScheme.primary.withValues(alpha: 0.7);
    }
  }

  static Color fileIconStripeBackground(
    String fileName,
    ColorScheme colorScheme,
  ) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return _pdfIconColor.withValues(alpha: 0.1);
      case 'doc':
      case 'docx':
        return _wordIconColor.withValues(alpha: 0.1);
      case 'xls':
      case 'xlsx':
        return _excelIconColor.withValues(alpha: 0.1);
      default:
        return colorScheme.primary.withValues(alpha: 0.05);
    }
  }

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _hover = false;

  /// Фон строки: выделение и hover через alphaBlend к [ColorScheme.surface], в тёмной теме сильнее.
  Color _rowBackground(ColorScheme scheme, Brightness brightness) {
    final base = scheme.surface;
    final isDark = brightness == Brightness.dark;
    if (widget.selection?.isSelected == true) {
      final selectedBase = Color.alphaBlend(
        scheme.primary.withValues(alpha: isDark ? 0.14 : 0.065),
        base,
      );
      if (!_hover) return selectedBase;
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: isDark ? 0.10 : 0.045),
        selectedBase,
      );
    }
    if (_hover) {
      return Color.alphaBlend(
        scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.05),
        base,
      );
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final desc = widget.file.description?.trim();
    final hasDescription = desc != null && desc.isNotEmpty;
    final sel = widget.selection;
    final selected = sel?.isSelected == true;
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.38)
        : colorScheme.outline.withValues(alpha: 0.1);
    final bg = _rowBackground(colorScheme, theme.brightness);

    final row = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sel != null)
              SizedBox(
                width: 40,
                child: Center(
                  child: Checkbox(
                    value: sel.isSelected,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: sel.onChanged,
                  ),
                ),
              ),
            Container(
              width: 48,
              color: _DocumentCard.fileIconStripeBackground(
                widget.file.name,
                colorScheme,
              ),
              child: Center(
                child: Icon(
                  _DocumentCard.getFileIcon(widget.file.name),
                  color: _DocumentCard.getFileIconColor(
                    widget.file.name,
                    colorScheme,
                  ),
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.file.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatFileSizeBytes(widget.file.size),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ContractDocumentStatusChip(
                            status: widget.file.documentStatus,
                          ),
                          Text(
                            'v${widget.file.documentVersion}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          if (widget.file.isAmendment)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.22,
                                  ),
                                ),
                              ),
                              child: Text(
                                'изм.',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.62,
                                  ),
                                  height: 1.1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Text(
                            'Загрузка: ${formatRuDateTime(widget.file.createdAt)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.48,
                              ),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showDescriptions && hasDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4, left: 2),
              child: widget.hideRowActions
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.all(6),
                          onPressed: widget.isDownloading
                              ? null
                              : widget.onDownload,
                          child: widget.isDownloading
                              ? Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: CupertinoActivityIndicator(
                                    radius: 7,
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                )
                              : Semantics(
                                  label: 'Скачать файл',
                                  button: true,
                                  child: const Icon(
                                    CupertinoIcons.cloud_download,
                                    size: 20,
                                  ),
                                ),
                        ),
                        PermissionGuard(
                          module: 'contracts',
                          permission: 'update',
                          child: CupertinoButton(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.all(6),
                            onPressed: widget.onEdit,
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: 18,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                        PermissionGuard(
                          module: 'contracts',
                          permission: 'update',
                          child: CupertinoButton(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.all(6),
                            onPressed: widget.onDelete,
                            child: Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: colorScheme.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) {
        if (!_hover) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover) setState(() => _hover = false);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: row,
      ),
    );
  }
}
