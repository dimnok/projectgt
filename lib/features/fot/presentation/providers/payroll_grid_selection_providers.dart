import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID сотрудников, отмеченных чекбоксами в таблице ФОТ (экспорт и др.).
final payrollGridSelectedEmployeeIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
