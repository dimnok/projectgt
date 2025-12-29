import '../../../../domain/entities/estimate.dart';
import 'dart:math' as math;

/// Утилита для сортировки позиций сметы.
class EstimateSorter {
  /// Основной метод сравнения двух позиций сметы по их номеру.
  static int compareByNumber(Estimate a, Estimate b) {
    final keyA = _parseNumberSortKey(a.number);
    final keyB = _parseNumberSortKey(b.number);

    final priorityDiff =
        keyA.category.priority.compareTo(keyB.category.priority);
    if (priorityDiff != 0) return priorityDiff;

    final minLength = math.min(keyA.segments.length, keyB.segments.length);
    for (var i = 0; i < minLength; i++) {
      final diff = keyA.segments[i].compareTo(keyB.segments[i]);
      if (diff != 0) return diff;
    }

    if (keyA.segments.length != keyB.segments.length) {
      return keyA.segments.length.compareTo(keyB.segments.length);
    }

    final rawCompare = keyA.normalized.compareTo(keyB.normalized);
    if (rawCompare != 0) return rawCompare;

    return a.id.compareTo(b.id);
  }

  static _EstimateNumberSortKey _parseNumberSortKey(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const _EstimateNumberSortKey.other();
    }

    // ignore: deprecated_member_use
    final simpleMatch = RegExp(r'^\d+$');
    if (simpleMatch.hasMatch(normalized)) {
      return _EstimateNumberSortKey(
        category: _EstimateNumberCategory.numeric,
        segments: [int.parse(normalized)],
        normalized: normalized,
      );
    }

    // ignore: deprecated_member_use
    final dottedMatch = RegExp(r'^\d+(?:\.\d+)+$');
    if (dottedMatch.hasMatch(normalized)) {
      final parts =
          normalized.split('.').map((part) => int.tryParse(part) ?? 0).toList();
      return _EstimateNumberSortKey(
        category: _EstimateNumberCategory.dotted,
        segments: parts,
        normalized: normalized,
      );
    }

    if (normalized.startsWith('д-')) {
      final tail = normalized.substring(2);
      final value = int.tryParse(tail) ?? 0;
      return _EstimateNumberSortKey(
        category: _EstimateNumberCategory.prefixedD,
        segments: [value],
        normalized: normalized,
      );
    }

    return _EstimateNumberSortKey(
      category: _EstimateNumberCategory.other,
      segments: const [],
      normalized: normalized,
    );
  }
}

enum _EstimateNumberCategory { numeric, dotted, prefixedD, other }

extension _EstimateNumberCategoryPriority on _EstimateNumberCategory {
  int get priority {
    switch (this) {
      case _EstimateNumberCategory.numeric:
        return 0;
      case _EstimateNumberCategory.dotted:
        return 1;
      case _EstimateNumberCategory.prefixedD:
        return 2;
      case _EstimateNumberCategory.other:
        return 3;
    }
  }
}

class _EstimateNumberSortKey {
  const _EstimateNumberSortKey({
    required this.category,
    required this.segments,
    required this.normalized,
  });

  const _EstimateNumberSortKey.other()
      : category = _EstimateNumberCategory.other,
        segments = const [],
        normalized = '';

  final _EstimateNumberCategory category;
  final List<int> segments;
  final String normalized;
}

