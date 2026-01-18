import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/work_search_export_server_service.dart';
import '../providers/work_search_provider.dart';
import '../providers/work_search_date_provider.dart';
import '../widgets/export_search_action.dart';

/// Действие в AppBar: кнопка экспорта результатов поиска в Excel
class WorkSearchExportAction extends ConsumerStatefulWidget {
  /// Конструктор действия экспорта.
  const WorkSearchExportAction({super.key});

  @override
  ConsumerState<WorkSearchExportAction> createState() =>
      _WorkSearchExportActionState();
}

class _WorkSearchExportActionState
    extends ConsumerState<WorkSearchExportAction> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(workSearchProvider);
    final hasResults = searchState.results.isNotEmpty;

    return Opacity(
      opacity: hasResults ? 1.0 : 0.5,
      child: IconButton(
        icon: _isExporting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : const Icon(Icons.download),
        tooltip:
            hasResults ? 'Экспортировать в Excel' : 'Нет данных для экспорта',
        onPressed: hasResults && !_isExporting ? _exportToPTO : null,
      ),
    );
  }

  /// Экспортирует результаты в формате ПТО
  Future<void> _exportToPTO() async {
    final searchState = ref.read(workSearchProvider);

    if (searchState.results.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для экспорта')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Создаем сервис
      final service = WorkSearchExportServerService(
        client: Supabase.instance.client,
      );

      // Получаем имя объекта и ID из первого результата
      final firstResult = searchState.results.first;
      final objectName = firstResult.objectName;
      final objectId = firstResult.objectId ?? '';

      // Получаем текущие фильтры из провайдеров
      final searchQuery = ref.read(exportSearchQueryProvider);
      final filters = ref.read(exportSearchFilterProvider);
      final dateRange = ref.read(workSearchDateRangeProvider);

      final systemFilters = filters['system']?.toList();
      final sectionFilters = filters['section']?.toList();
      final floorFilters = filters['floor']?.toList();

      // ЗАГРУЖАЕМ ВСЕ ДАННЫЕ (без пагинации) с сервера
      final allResults = await service.loadAllSearchResults(
        objectId: objectId,
        objectName: objectName,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
        systemFilters: systemFilters,
        sectionFilters: sectionFilters,
        floorFilters: floorFilters,
      );

      if (!mounted) return;

      if (allResults.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет данных для экспорта')),
        );
        return;
      }

      // ВЫЗЫВАЕМ ЭКСПОРТ со ВСЕМИ ДАННЫМИ
      final result = await service.exportToPTO(
        results: allResults,
        objectName: objectName,
        contractName: 'Экспорт',
      );

      if (!mounted) return;

      // Если пользователь отменил выбор файла на Desktop, ничего не показываем
      if (result.filePath == 'cancelled') return;

      // Показываем сообщение об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл "${result.filename}" успешно экспортирован'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
