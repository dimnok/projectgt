import 'dart:developer' as developer;

/// Статусы заявки на закупку (значения в БД).
enum PurchaseRequestStatus {
  /// Черновик.
  draft,

  /// На согласовании.
  approval,

  /// На доработке.
  revision,

  /// Формирование счета.
  invoicePreparation,

  /// Согласование счета.
  invoiceApproval,

  /// Передано бухгалтеру.
  accounting,

  /// Заведено на оплату.
  paymentQueue,

  /// Оплачено.
  paid,

  /// Получено.
  received,

  /// Отменено.
  cancelled,

  /// Неизвестный статус (не из БД, только для отображения при ошибке данных).
  unknown,
}

/// Расширения для [PurchaseRequestStatus].
extension PurchaseRequestStatusX on PurchaseRequestStatus {
  /// Значение в колонке `status`.
  String get dbValue => switch (this) {
        PurchaseRequestStatus.draft => 'draft',
        PurchaseRequestStatus.approval => 'approval',
        PurchaseRequestStatus.revision => 'revision',
        PurchaseRequestStatus.invoicePreparation => 'invoice_preparation',
        PurchaseRequestStatus.invoiceApproval => 'invoice_approval',
        PurchaseRequestStatus.accounting => 'accounting',
        PurchaseRequestStatus.paymentQueue => 'payment_queue',
        PurchaseRequestStatus.paid => 'paid',
        PurchaseRequestStatus.received => 'received',
        PurchaseRequestStatus.cancelled => 'cancelled',
        PurchaseRequestStatus.unknown => 'unknown',
      };

  /// Пользовательское название статуса.
  String get displayName => switch (this) {
        PurchaseRequestStatus.draft => 'Черновик',
        PurchaseRequestStatus.approval => 'На согласовании',
        PurchaseRequestStatus.revision => 'На доработке',
        PurchaseRequestStatus.invoicePreparation => 'Формирование счета',
        PurchaseRequestStatus.invoiceApproval => 'Согласование счета',
        PurchaseRequestStatus.accounting => 'Передано бухгалтеру',
        PurchaseRequestStatus.paymentQueue => 'Заведено на оплату',
        PurchaseRequestStatus.paid => 'Оплачено',
        PurchaseRequestStatus.received => 'Получено',
        PurchaseRequestStatus.cancelled => 'Отменено',
        PurchaseRequestStatus.unknown => 'Неизвестный статус',
      };

  /// Парсинг из строки БД.
  static PurchaseRequestStatus? fromDb(String? value) {
    if (value == null) return null;
    for (final s in PurchaseRequestStatus.values) {
      if (s == PurchaseRequestStatus.unknown) continue;
      if (s.dbValue == value) return s;
    }
    return null;
  }

  /// Парсинг из БД с логированием и [PurchaseRequestStatus.unknown] при сбое.
  static PurchaseRequestStatus parseFromDb(
    String? value, {
    String? context,
  }) {
    final parsed = fromDb(value);
    if (parsed != null) return parsed;

    if (value != null && value.isNotEmpty) {
      developer.log(
        'Неизвестный статус заявки: $value'
        '${context != null ? ' ($context)' : ''}',
        name: 'PurchaseRequestStatus',
      );
    }
    return PurchaseRequestStatus.unknown;
  }
}

/// Фильтр списка заявок (RPC `purchase_request_list`).
enum PurchaseRequestListFilter {
  /// Мои заявки.
  mine,

  /// На мне.
  onMe,

  /// Все доступные.
  all,

  /// Архив (получено / отменено).
  archive,
}

/// Расширения для [PurchaseRequestListFilter].
extension PurchaseRequestListFilterX on PurchaseRequestListFilter {
  /// Параметр `p_filter` для RPC.
  String get rpcValue => switch (this) {
        PurchaseRequestListFilter.mine => 'mine',
        PurchaseRequestListFilter.onMe => 'on_me',
        PurchaseRequestListFilter.all => 'all',
        PurchaseRequestListFilter.archive => 'archive',
      };

  /// Подпись для UI.
  String get label => switch (this) {
        PurchaseRequestListFilter.mine => 'Мои',
        PurchaseRequestListFilter.onMe => 'На мне',
        PurchaseRequestListFilter.all => 'Все',
        PurchaseRequestListFilter.archive => 'Архив',
      };
}
