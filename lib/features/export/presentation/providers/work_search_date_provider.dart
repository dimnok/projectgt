import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Выбранный период дат для модуля поиска работ (независимо от выгрузки)
final workSearchDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

