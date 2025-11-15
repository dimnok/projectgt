import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Экран справочника категорий ТМЦ.
class InventoryCategoriesReferenceScreen extends ConsumerStatefulWidget {
  /// Создаёт экран справочника категорий ТМЦ.
  const InventoryCategoriesReferenceScreen({super.key});

  @override
  ConsumerState<InventoryCategoriesReferenceScreen> createState() =>
      _InventoryCategoriesReferenceScreenState();
}

class _InventoryCategoriesReferenceScreenState
    extends ConsumerState<InventoryCategoriesReferenceScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCategories() async {
    final client = Supabase.instance.client;
    final response = await client
        .from('inventory_categories')
        .select()
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerBackgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final rowBackgroundColor = theme.colorScheme.surface;
    final alternateRowColor = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.black.withValues(alpha: 0.02);

    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Справочник категорий ТМЦ',
        leading: BackButton(),
        showThemeSwitch: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки данных',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final categories = snapshot.data ?? [];

            if (categories.isEmpty) {
              return Center(
                child: Text(
                  'Категории не найдены',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 32,
                        ),
                        child: Table(
                          border: TableBorder(
                            top: BorderSide(color: dividerColor, width: 1),
                            bottom: BorderSide(color: dividerColor, width: 1),
                            left: BorderSide.none,
                            right: BorderSide.none,
                            horizontalInside: BorderSide(color: dividerColor, width: 1),
                            verticalInside: BorderSide(color: dividerColor, width: 1),
                          ),
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          columnWidths: const <int, TableColumnWidth>{
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(1),
                            5: FlexColumnWidth(2.5),
                          },
                        children: [
                          // Заголовок
                          TableRow(
                            decoration: BoxDecoration(color: headerBackgroundColor),
                            children: [
                              _buildHeaderCell(
                                theme,
                                'Название',
                                TextAlign.left,
                              ),
                              _buildHeaderCell(
                                theme,
                                'Префикс',
                                TextAlign.center,
                              ),
                              _buildHeaderCell(
                                theme,
                                'Серийный\nномер',
                                TextAlign.center,
                              ),
                              _buildHeaderCell(
                                theme,
                                'Срок службы\nобязателен',
                                TextAlign.center,
                              ),
                              _buildHeaderCell(
                                theme,
                                'Срок службы\n(мес.)',
                                TextAlign.center,
                              ),
                              _buildHeaderCell(
                                theme,
                                'Описание',
                                TextAlign.left,
                              ),
                            ],
                          ),
                          // Строки данных
                          for (int i = 0; i < categories.length; i++)
                            TableRow(
                              decoration: BoxDecoration(
                                color: i % 2 == 0 ? rowBackgroundColor : alternateRowColor,
                              ),
                              children: [
                                _buildDataCell(
                                  theme,
                                  categories[i]['name'] as String? ?? 'Без названия',
                                  TextAlign.left,
                                ),
                                _buildDataCell(
                                  theme,
                                  categories[i]['prefix'] as String? ?? '—',
                                  TextAlign.center,
                                ),
                                _buildDataCell(
                                  theme,
                                  (categories[i]['serial_number_required'] == true)
                                      ? 'Да'
                                      : 'Нет',
                                  TextAlign.center,
                                ),
                                _buildDataCell(
                                  theme,
                                  (categories[i]['service_life_required'] == true)
                                      ? 'Да'
                                      : 'Нет',
                                  TextAlign.center,
                                ),
                                _buildDataCell(
                                  theme,
                                  categories[i]['service_life_months'] != null
                                      ? '${categories[i]['service_life_months']}'
                                      : '—',
                                  TextAlign.center,
                                ),
                                _buildDataCell(
                                  theme,
                                  categories[i]['description'] as String? ?? '—',
                                  TextAlign.left,
                                ),
                              ],
                            ),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(ThemeData theme, String text, TextAlign align) {
    Alignment alignment;
    switch (align) {
      case TextAlign.center:
        alignment = Alignment.center;
        break;
      case TextAlign.right:
        alignment = Alignment.centerRight;
        break;
      default:
        alignment = Alignment.centerLeft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: alignment,
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildDataCell(ThemeData theme, String text, TextAlign align) {
    Alignment alignment;
    switch (align) {
      case TextAlign.center:
        alignment = Alignment.center;
        break;
      case TextAlign.right:
        alignment = Alignment.centerRight;
        break;
      default:
        alignment = Alignment.centerLeft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: alignment,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
        textAlign: align,
      ),
    );
  }
}

