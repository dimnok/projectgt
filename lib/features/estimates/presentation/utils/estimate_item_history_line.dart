import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/estimate_item_history.dart';

const _fieldOrder = <String>[
  'quantity',
  'price',
  'name',
  'number',
  'unit',
  'system',
  'subsystem',
  'article',
  'manufacturer',
  'visible_in_estimates_module',
];

const _fieldLabels = <String, String>{
  'quantity': 'количество',
  'price': 'цена',
  'name': 'наименование',
  'number': 'номер',
  'unit': 'ед. изм.',
  'system': 'система',
  'subsystem': 'подсистема',
  'article': 'артикул',
  'manufacturer': 'производитель',
  'visible_in_estimates_module': 'видимость',
};

/// Собирает одну строку журнала: «Действие · дата · автор».
String formatEstimateItemHistoryLine({
  required String action,
  DateTime? at,
  String? who,
  String? details,
}) {
  final trimmedWho = who?.trim();
  final trimmedDetails = details?.trim();
  return [
    action,
    if (trimmedDetails != null && trimmedDetails.isNotEmpty) trimmedDetails,
    if (at != null) formatRuDateTime(at),
    if (trimmedWho != null && trimmedWho.isNotEmpty) trimmedWho,
  ].join(' · ');
}

/// Строка добавления позиции из полей сметы.
String formatEstimateAdditionHistoryLine(Estimate estimate) {
  return formatEstimateItemHistoryLine(
    action: 'Добавление',
    at: estimate.createdAt,
    who: estimate.createdByName,
  );
}

/// Строки журнала: добавление и каждое поле правки, от ранних к поздним.
List<String> buildEstimateItemHistoryLines({
  required Estimate estimate,
  required List<EstimateItemHistoryEntry> entries,
}) {
  final events = <_HistoryEvent>[];
  var sequence = 0;

  events.add(
    _HistoryEvent(
      at: estimate.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      sequence: sequence++,
      line: formatEstimateAdditionHistoryLine(estimate),
    ),
  );

  final sortedEntries = [...entries]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  for (final entry in sortedEntries) {
    final fieldDetails = _changeDetailLines(entry.changes);
    if (fieldDetails.isEmpty) {
      events.add(
        _HistoryEvent(
          at: entry.createdAt,
          sequence: sequence++,
          line: formatEstimateItemHistoryLine(
            action: 'Изменение',
            at: entry.createdAt,
            who: entry.userName,
          ),
        ),
      );
      continue;
    }
    for (final details in fieldDetails) {
      events.add(
        _HistoryEvent(
          at: entry.createdAt,
          sequence: sequence++,
          line: formatEstimateItemHistoryLine(
            action: 'Изменение',
            details: details,
            at: entry.createdAt,
            who: entry.userName,
          ),
        ),
      );
    }
  }

  events.sort((a, b) {
    final byTime = a.at.compareTo(b.at);
    if (byTime != 0) return byTime;
    return a.sequence.compareTo(b.sequence);
  });
  return events.map((event) => event.line).toList();
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.at,
    required this.sequence,
    required this.line,
  });

  final DateTime at;
  final int sequence;
  final String line;
}

List<String> _changeDetailLines(Map<String, EstimateItemFieldChange> changes) {
  if (changes.isEmpty) return const [];
  final parts = <String>[];
  for (final field in _fieldOrder) {
    final change = changes[field];
    if (change == null) continue;
    parts.add(_formatFieldChange(field, change));
  }
  for (final entry in changes.entries) {
    if (_fieldOrder.contains(entry.key)) continue;
    parts.add(_formatFieldChange(entry.key, entry.value));
  }
  return parts;
}

String _formatFieldChange(String field, EstimateItemFieldChange change) {
  final label = _fieldLabels[field] ?? field;
  return '$label ${_formatChangeValue(field, change.from)} → ${_formatChangeValue(field, change.to)}';
}

String _formatChangeValue(String field, Object? value) {
  if (field == 'quantity' && value is num) {
    return formatQuantity(value);
  }
  if (field == 'price' && value is num) {
    return formatCurrency(value);
  }
  if (field == 'visible_in_estimates_module') {
    if (value == true) return 'да';
    if (value == false) return 'нет';
  }
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '—';
  if (text.length > 40) return '${text.substring(0, 37)}...';
  return text;
}
