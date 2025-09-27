import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/materials_mapping_providers.dart';
import '../providers/materials_providers.dart';

/// Кнопка "Связь": открывает диалог со списком материалов (из модуля Материал)
/// для привязки алиасов к сметной позиции.
class MaterialsLinkButton extends ConsumerWidget {
  /// Идентификатор сметной строки, к которой выполняется привязка.
  final String estimateId;

  /// Количество уже связанных алиасов (визуальная индикация).
  final int aliasCount;

  /// Конструктор кнопки привязки материалов.
  /// Конструктор кнопки привязки материалов.
  const MaterialsLinkButton({
    super.key,
    required this.estimateId,
    required this.aliasCount,
  });

  /// Построение виджета кнопки привязки.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color bg = aliasCount > 0 ? Colors.green : Colors.red;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _openDialog(context, ref),
      minimumSize: const Size(0, 0),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Открывает диалог и обновляет список после закрытия.
  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => _MaterialsListDialog(estimateId: estimateId),
    );
    // После закрытия диалога — обновляем список через пагинатор
    ref.read(estimatesMappingPagerProvider.notifier).refresh();
  }
}

/// Диалог со списком материалов из модуля "Материал".
/// Пока MVP: просто список имен из таблицы `materials` с поиском.
class _MaterialsListDialog extends ConsumerStatefulWidget {
  final String estimateId;

  /// Конструктор диалога выбора материала.
  const _MaterialsListDialog({required this.estimateId});

  @override
  ConsumerState<_MaterialsListDialog> createState() =>
      _MaterialsListDialogState();
}

class _MaterialsListDialogState extends ConsumerState<_MaterialsListDialog> {
  String _query = '';
  bool _loading = false;
  List<Map<String, dynamic>> _items = const [];
  bool _saving = false;
  // удалён неиспользуемый текст сметного наименования; работаем с нормализованным
  String? _targetNameNorm;
  Set<String> _takenAliasNorms = <String>{};
  bool _takenLoaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Начальная загрузка данных диалога (заполненные алиасы, список материалов).
  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await _fetchTakenAliases();
      await _load();
      await _fetchTargetName();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Загружает список материалов c сервера с учётом фильтров.
  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    final selectedContract = ref.read(selectedContractNumberProvider);
    var builder = client
        .from('materials')
        .select('id,name,unit,receipt_number,receipt_date');
    if (selectedContract != null && selectedContract.trim().isNotEmpty) {
      builder = builder.eq('contract_number', selectedContract.trim());
    }
    final data =
        await builder.order('receipt_date', ascending: false).limit(200);
    final raw = (data as List)
        .map((e) => {
              'id': e['id']?.toString() ?? '',
              'name': e['name']?.toString() ?? '',
              'unit': e['unit']?.toString(),
              'receipt_number': e['receipt_number']?.toString(),
            })
        .toList();

    setState(() {
      _items = raw;
    });
  }

  /// Загружает уже занятые алиасы для исключения из списка.
  Future<void> _fetchTakenAliases() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final rows = await client.from('material_aliases').select('alias_raw');
      final set = <String>{};
      for (final r in rows as List) {
        final a = (r['alias_raw']?.toString() ?? '');
        final nn = _normalize(a);
        if (nn.isNotEmpty) set.add(nn);
      }
      if (mounted) {
        setState(() {
          _takenAliasNorms = set;
          _takenLoaded = true;
        });
      }
    } catch (_) {
      // игнорируем
    }
  }

  /// Получает нормализованное имя сметной позиции для сортировки по схожести.
  Future<void> _fetchTargetName() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client
          .from('estimates')
          .select('name')
          .eq('id', widget.estimateId)
          .maybeSingle();
      final n = res != null ? (res['name']?.toString() ?? '') : '';
      setState(() {
        _targetNameNorm = _normalize(n);
      });
    } catch (_) {
      // игнорируем, просто не будет приоритезации
    }
  }

  /// Нормализует строку для улучшения сравнения по схожести.
  String _normalize(String s) {
    final lowered = s.toLowerCase();
    final mapM = lowered.replaceAll('М', 'м');
    final latinM = mapM.replaceAll('м8', 'm8').replaceAll('м10', 'm10');
    final collapsed = latinM.replaceAll(RegExp(r"[\s_]+"), ' ');
    final cleaned = collapsed.replaceAll(RegExp(r"[\.,;:/\\-]+"), ' ');
    return cleaned.trim();
  }

  /// Вычисляет эвристический балл схожести названий.
  int _similarityScore(String name, {String? unit, String? target}) {
    final base = target ?? _targetNameNorm ?? '';
    if (base.isEmpty) return 0;
    final a = _normalize(name);
    final b = base;
    int score = 0;
    if (a == b) score += 120;
    if (a.contains(b)) score += 80;
    if (b.contains(a)) score += 60;
    // токены
    final at = a.split(' ');
    final bt = b.split(' ');
    final aset = at.where((t) => t.isNotEmpty).toSet();
    final bset = bt.where((t) => t.isNotEmpty).toSet();
    final inter = aset.intersection(bset);
    score += inter.length * 12;
    // префиксное совпадение
    if (a.startsWith(bt.first)) score += 10;
    // учесть единицу
    final u = (unit ?? '').toLowerCase();
    if (u.isNotEmpty && (b.contains(u) || a.contains(u))) score += 2;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Базовая фильтрация по поиску
    List<Map<String, dynamic>> filtered = _items.where((e) {
      if (_query.trim().isEmpty) return true;
      final s =
          '${e['name'] ?? ''} ${e['unit'] ?? ''}'.toString().toLowerCase();
      return s.contains(_query.toLowerCase());
    }).toList();

    // Дополнительно скрыть уже привязанные материалы по нормализованному имени
    if (_takenLoaded && _takenAliasNorms.isNotEmpty) {
      filtered = filtered
          .where((e) => !_takenAliasNorms
              .contains(_normalize(e['name']?.toString() ?? '')))
          .toList();
    }

    // Сортировка по схожести
    if (_query.trim().isNotEmpty) {
      final qNorm = _normalize(_query);
      filtered.sort((a, b) {
        final sa = _similarityScore(a['name'] as String,
            unit: a['unit']?.toString(), target: qNorm);
        final sb = _similarityScore(b['name'] as String,
            unit: b['unit']?.toString(), target: qNorm);
        return sb.compareTo(sa);
      });
    } else if ((_targetNameNorm ?? '').isNotEmpty) {
      filtered.sort((a, b) {
        final sa =
            _similarityScore(a['name'] as String, unit: a['unit']?.toString());
        final sb =
            _similarityScore(b['name'] as String, unit: b['unit']?.toString());
        return sb.compareTo(sa);
      });
    }

    return AlertDialog(
      title: const Text('Выберите материал из накладных'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск по названию/ед. изм.',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            if (_loading || _saving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final it = filtered[index];
                    return ListTile(
                      title: Text(
                        '${it['name']} (${it['unit']?.toString() ?? '—'})',
                      ),
                      onTap: () => _linkMaterial(it),
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  itemCount: filtered.length,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  /// Привязывает выбранный материал как алиас к сметной позиции.
  Future<void> _linkMaterial(Map<String, dynamic> it) async {
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final String alias = (it['name']?.toString() ?? '').trim();
      final String? uom = it['unit']?.toString();
      if (alias.isEmpty) {
        setState(() => _saving = false);
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      // Пытаемся создать алиас. Уникальность по (estimate_id, normalized_alias, supplier_id)
      try {
        await client.from('material_aliases').insert({
          'estimate_id': widget.estimateId,
          'alias_raw': alias,
          'uom_raw': uom,
          'multiplier_to_estimate': 1,
        });
      } catch (_) {
        // Игнорируем ошибку уникальности — связь уже существует
      }

      // Локально помечаем выбранное имя занятым, чтобы мгновенно исключить из списка
      _takenAliasNorms.add(_normalize(alias));

      if (!mounted) return;
      Navigator.of(context).pop(it);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
