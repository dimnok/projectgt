import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
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
    String? objectId,
    PurchaseRequestStatus? status,
    String? createdBy,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  });

  /// Карточка заявки.
  Future<PurchaseRequest?> getRequest(String id);

  /// Позиции заявки.
  Future<List<PurchaseRequestItem>> getItems(String requestId);

  /// История заявки.
  Future<List<PurchaseRequestHistoryEntry>> getHistory(String requestId);

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

  /// Обновить шапку (черновик / доработка).
  Future<void> updateHeader({
    required String requestId,
    required String objectId,
    String? comment,
  });

  /// Удалить черновик.
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

  /// Обновить позицию.
  Future<PurchaseRequestItem> updateItem(PurchaseRequestItem item);

  /// Удалить позицию.
  Future<void> deleteItem(String itemId);

  /// Отправить / отправить повторно.
  Future<PurchaseRequest> submit(String requestId, {String? comment});

  /// Согласовать заявку.
  Future<PurchaseRequest> approve(String requestId, {String? comment});

  /// Вернуть на доработку.
  Future<PurchaseRequest> returnForRevision(
    String requestId, {
    required String comment,
  });

  /// Отправить счета на согласование.
  Future<PurchaseRequest> submitInvoices(String requestId);

  /// Согласовать счета.
  Future<PurchaseRequest> approveInvoice(String requestId, {String? comment});

  /// Вернуть счета на доработку.
  Future<PurchaseRequest> returnInvoice(
    String requestId, {
    required String comment,
  });

  /// Заведено на оплату.
  Future<PurchaseRequest> queuePayment(String requestId, {String? comment});

  /// Оплачено.
  Future<PurchaseRequest> markPaid(
    String requestId, {
    DateTime? paymentDate,
    String? comment,
  });

  /// Материал получен.
  Future<PurchaseRequest> markReceived(
    String requestId, {
    DateTime? receivedDate,
    String? comment,
  });

  /// Отменить заявку.
  Future<PurchaseRequest> cancel(
    String requestId, {
    required String comment,
  });
}
