import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_company_user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_list_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Репозиторий заявок на закупку.
abstract class PurchaseRequestRepository {
  /// Список заявок (RPC).
  Future<List<PurchaseRequestListItem>> list({
    required PurchaseRequestListFilter filter,
    String? search,
    int limit = 50,
  });

  /// Количество заявок по категориям фильтра (RPC).
  Future<Map<PurchaseRequestListFilter, int>> getCounts({String? search});

  /// Карточка заявки.
  Future<PurchaseRequest?> getRequest(String id);

  /// Позиции заявки.
  Future<List<PurchaseRequestItem>> getItems(String requestId);

  /// История заявки.
  Future<List<PurchaseRequestHistoryEntry>> getHistory(String requestId);

  /// Счета заявки с прикреплёнными файлами.
  Future<List<PurchaseRequestInvoice>> getInvoices(String requestId);

  /// Создать счёт и прикрепить файл (type = invoice).
  Future<PurchaseRequestInvoice> createInvoiceWithFile({
    required String requestId,
    required String supplierId,
    required double amount,
    required List<int> fileBytes,
    required String fileName,
    String? invoiceNumber,
    DateTime? invoiceDate,
    String? comment,
  });

  /// Удалить счёт и связанные файлы в Storage.
  Future<void> deleteInvoice(String invoiceId);

  /// Скачать файл счёта из Storage по пути записи.
  Future<List<int>> downloadInvoiceFile(String storagePath);

  /// Настройки модуля для активной компании.
  Future<PurchaseRequestSettings?> getSettings();

  /// Активные пользователи компании (для настройки маршрута).
  Future<List<PurchaseRequestCompanyUser>> getCompanyUsers();

  /// Сохранить настройки маршрута.
  Future<PurchaseRequestSettings> upsertSettings(
    PurchaseRequestSettings settings,
  );

  /// Создать черновик.
  Future<String> createDraft({
    required String objectId,
    String? comment,
  });

  /// Обновить шапку своего черновика (объект, комментарий).
  Future<void> updateHeader({
    required String requestId,
    required String objectId,
    String? comment,
  });

  /// Удалить свой черновик.
  Future<void> deleteDraft(String requestId);

  /// Добавить позицию.
  Future<PurchaseRequestItem> addItem({
    required String requestId,
    required String name,
    required double quantity,
    required String unit,
    String? article,
    String? comment,
  });

  /// Удалить позицию.
  Future<void> deleteItem(String itemId);

  /// Обновить позицию.
  Future<PurchaseRequestItem> updateItem(PurchaseRequestItem item);

  /// Отправить / отправить повторно.
  Future<PurchaseRequest> submit(String requestId);

  /// Согласовать заявку.
  Future<PurchaseRequest> approve(String requestId);

  /// Вернуть на доработку.
  Future<PurchaseRequest> returnForRevision(
    String requestId, {
    required String comment,
  });

  /// Отправить счета на согласование.
  Future<PurchaseRequest> submitInvoices(String requestId);

  /// Согласовать счета.
  Future<PurchaseRequest> approveInvoice(String requestId);

  /// Вернуть счета на доработку.
  Future<PurchaseRequest> returnInvoice(
    String requestId, {
    required String comment,
  });

  /// Заведено на оплату.
  Future<PurchaseRequest> queuePayment(String requestId);

  /// Оплачено.
  Future<PurchaseRequest> markPaid(String requestId);

  /// Материал получен.
  Future<PurchaseRequest> markReceived(String requestId);
}
