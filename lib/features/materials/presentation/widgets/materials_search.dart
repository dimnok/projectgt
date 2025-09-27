import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/material_item.dart';

/// Провайдеры состояния поиска (разделены по scope экрана)
final materialsSearchQueryProvider =
    StateProvider.family<String, String>((ref, scope) => '');

/// Видимость поля поиска для указанного scope.
final materialsSearchVisibleProvider =
    StateProvider.family<bool, String>((ref, scope) => false);

/// Контроллер поля ввода (пер-экранный scope) с авто-диспозом
final _materialsSearchControllerProvider =
    Provider.autoDispose.family<TextEditingController, String>((ref, scope) {
  final initial = ref.read(materialsSearchQueryProvider(scope));
  final c = TextEditingController(text: initial);
  ref.onDispose(c.dispose);
  // Синхронизируемся при внешнем изменении провайдера
  ref.listen<String>(materialsSearchQueryProvider(scope), (prev, next) {
    if (c.text != next) {
      c.text = next;
      c.selection = TextSelection.fromPosition(
        TextPosition(offset: c.text.length),
      );
    }
  });
  return c;
});

/// Виджет действий поиска для AppBar: анимированное поле + кнопка лупы
class MaterialsSearchAction extends ConsumerWidget {
  /// Область применения поиска, например: 'materials' | 'mapping'.
  final String scope; // например: 'materials' | 'mapping'
  /// Конструктор виджета действий поиска.
  const MaterialsSearchAction({super.key, required this.scope});

  /// Рендерит действия поиска в AppBar.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visible = ref.watch(materialsSearchVisibleProvider(scope));
    final query = ref.watch(materialsSearchQueryProvider(scope));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: visible ? 450 : 0,
          child: visible
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.06),
                          blurRadius: 1,
                          offset: const Offset(-1, -1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller:
                          ref.watch(_materialsSearchControllerProvider(scope)),
                      autofocus: true,
                      onChanged: (v) => ref
                          .read(materialsSearchQueryProvider(scope).notifier)
                          .state = v,
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        isDense: true,
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          icon: Icon(
            query.trim().isNotEmpty ? Icons.close : Icons.search,
            color: query.trim().isNotEmpty ? Colors.red : null,
          ),
          onPressed: () {
            if (query.trim().isNotEmpty) {
              ref.read(materialsSearchQueryProvider(scope).notifier).state = '';
            } else {
              final v = !ref.read(materialsSearchVisibleProvider(scope));
              ref.read(materialsSearchVisibleProvider(scope).notifier).state =
                  v;
            }
          },
        ),
      ],
    );
  }
}

/// Утилита фильтрации по строке запроса
List<MaterialItem> filterMaterials(
  List<MaterialItem> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((m) {
    final name = m.name.toLowerCase();
    final unit = (m.unit ?? '').toLowerCase();
    final rn = (m.receiptNumber ?? '').toLowerCase();
    return name.contains(q) || unit.contains(q) || rn.contains(q);
  }).toList();
}
