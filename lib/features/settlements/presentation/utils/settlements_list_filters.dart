import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlements_filter_options.dart';

/// Состояние и логика фильтров реестра взаиморасчётов (клиентская фильтрация).
class SettlementsListFilters {
  /// Создаёт фильтры.
  const SettlementsListFilters({
    this.search = '',
    this.contractorId,
    this.objectId,
    this.contractId,
    this.operationType,
    this.paymentStatus,
  });

  /// Строка поиска.
  final String search;

  /// Контрагент.
  final String? contractorId;

  /// Объект.
  final String? objectId;

  /// Договор.
  final String? contractId;

  /// Тип операции.
  final SettlementOperationType? operationType;

  /// Статус оплаты.
  final SettlementPaymentStatus? paymentStatus;

  @override
  bool operator ==(Object other) {
    return other is SettlementsListFilters &&
        other.search == search &&
        other.contractorId == contractorId &&
        other.objectId == objectId &&
        other.contractId == contractId &&
        other.operationType == operationType &&
        other.paymentStatus == paymentStatus;
  }

  @override
  int get hashCode => Object.hash(
    search,
    contractorId,
    objectId,
    contractId,
    operationType,
    paymentStatus,
  );

  /// Есть хотя бы один активный фильтр.
  bool get hasActive =>
      search.trim().isNotEmpty ||
      contractorId != null ||
      objectId != null ||
      contractId != null ||
      operationType != null ||
      paymentStatus != null;

  /// Сброс всех фильтров.
  SettlementsListFilters cleared() => const SettlementsListFilters();

  /// Копия с изменениями.
  SettlementsListFilters copyWith({
    String? search,
    String? contractorId,
    String? objectId,
    String? contractId,
    SettlementOperationType? operationType,
    SettlementPaymentStatus? paymentStatus,
    bool clearContractor = false,
    bool clearObject = false,
    bool clearContract = false,
    bool clearOperationType = false,
    bool clearPaymentStatus = false,
  }) {
    return SettlementsListFilters(
      search: search ?? this.search,
      contractorId: clearContractor
          ? null
          : (contractorId ?? this.contractorId),
      objectId: clearObject ? null : (objectId ?? this.objectId),
      contractId: clearContract ? null : (contractId ?? this.contractId),
      operationType: clearOperationType
          ? null
          : (operationType ?? this.operationType),
      paymentStatus: clearPaymentStatus
          ? null
          : (paymentStatus ?? this.paymentStatus),
    );
  }

  /// Контрагенты, совместимые с выбранными объектом и договором.
  List<SettlementsFilterOption> contractorOptions(
    List<SettlementOperation> operations,
  ) {
    return SettlementsFilterOptionsBuilder.contractors(
      _entityScope(operations, ignoreContractor: true),
    );
  }

  /// Объекты, совместимые с выбранным контрагентом и договором.
  List<SettlementsFilterOption> objectOptions(
    List<SettlementOperation> operations,
  ) {
    return SettlementsFilterOptionsBuilder.objects(
      _entityScope(operations, ignoreObject: true),
    );
  }

  /// Договоры, совместимые с выбранным контрагентом и объектом.
  List<SettlementsFilterOption> contractOptions(
    List<SettlementOperation> operations,
  ) {
    return SettlementsFilterOptionsBuilder.contracts(
      _entityScope(operations, ignoreContract: true),
    );
  }

  /// Применить фильтры к списку операций.
  List<SettlementOperation> apply(List<SettlementOperation> operations) {
    final query = search.trim().toLowerCase();
    return operations
        .where((op) {
          if (operationType != null && op.operationType != operationType) {
            return false;
          }
          if (paymentStatus != null &&
              op.resolvedPaymentStatus != paymentStatus) {
            return false;
          }
          if (contractorId != null && op.contractorId != contractorId) {
            return false;
          }
          if (objectId != null && op.objectId != objectId) {
            return false;
          }
          if (contractId != null && op.contractId != contractId) {
            return false;
          }
          if (query.isEmpty) return true;
          return op.invoiceNumber.toLowerCase().contains(query) ||
              (op.actNumber?.toLowerCase().contains(query) ?? false) ||
              (op.contractNumber?.toLowerCase().contains(query) ?? false) ||
              (op.contractorName?.toLowerCase().contains(query) ?? false) ||
              (op.objectName?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  /// Синхронизация после смены данных (удаление устаревших значений).
  SettlementsListFilters syncedWith(List<SettlementOperation> operations) {
    return _pruneIncompatible(operations);
  }

  /// Выбор контрагента с каскадной проверкой зависимых фильтров.
  SettlementsListFilters withContractor(
    String? id,
    List<SettlementOperation> operations,
  ) {
    return _pruneIncompatible(
      operations,
      copyWith(contractorId: id, clearContractor: id == null),
    );
  }

  /// Выбор объекта с каскадной проверкой зависимых фильтров.
  SettlementsListFilters withObject(
    String? id,
    List<SettlementOperation> operations,
  ) {
    if (id == null) {
      return _pruneIncompatible(
        operations,
        copyWith(clearObject: true, clearContract: true),
      );
    }
    return _pruneIncompatible(
      operations,
      copyWith(objectId: id),
    );
  }

  /// Выбор договора: подставляет связанные контрагента и объект.
  SettlementsListFilters withContract(
    String? id,
    List<SettlementOperation> operations,
  ) {
    if (id == null) {
      return _pruneIncompatible(operations, copyWith(clearContract: true));
    }

    SettlementOperation? match;
    for (final op in operations) {
      if (op.contractId == id) {
        match = op;
        break;
      }
    }
    if (match == null) {
      return copyWith(clearContract: true);
    }

    return _pruneIncompatible(
      operations,
      copyWith(
        contractId: id,
        contractorId: match.contractorId,
        objectId: match.objectId,
      ),
    );
  }

  List<SettlementOperation> _entityScope(
    List<SettlementOperation> operations, {
    bool ignoreContractor = false,
    bool ignoreObject = false,
    bool ignoreContract = false,
  }) {
    return operations
        .where((op) {
          if (!ignoreContractor &&
              contractorId != null &&
              op.contractorId != contractorId) {
            return false;
          }
          if (!ignoreObject && objectId != null && op.objectId != objectId) {
            return false;
          }
          if (!ignoreContract &&
              contractId != null &&
              op.contractId != contractId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  SettlementsListFilters _pruneIncompatible(
    List<SettlementOperation> operations, [
    SettlementsListFilters? base,
  ]) {
    var next = base ?? this;

    if (next.contractorId != null &&
        !operations.any((op) => op.contractorId == next.contractorId)) {
      next = next.copyWith(clearContractor: true);
    }
    if (next.objectId != null &&
        !operations.any((op) => op.objectId == next.objectId)) {
      next = next.copyWith(clearObject: true);
    }
    if (next.contractId != null &&
        !operations.any((op) => op.contractId == next.contractId)) {
      next = next.copyWith(clearContract: true);
    }

    if (next.contractorId != null &&
        next.objectId != null &&
        !operations.any(
          (op) =>
              op.contractorId == next.contractorId &&
              op.objectId == next.objectId,
        )) {
      next = next.copyWith(clearObject: true, clearContract: true);
    }

    if (next.contractorId != null &&
        next.contractId != null &&
        !operations.any(
          (op) =>
              op.contractorId == next.contractorId &&
              op.contractId == next.contractId,
        )) {
      next = next.copyWith(clearContract: true);
    }

    if (next.objectId != null &&
        next.contractId != null &&
        !operations.any(
          (op) =>
              op.objectId == next.objectId && op.contractId == next.contractId,
        )) {
      next = next.copyWith(clearContract: true);
    }

    return next;
  }
}
