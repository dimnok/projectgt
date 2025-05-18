import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:logger/logger.dart';

part 'contract_model.freezed.dart';
part 'contract_model.g.dart';

/// Data-модель договора для работы с API и хранения в базе.
///
/// Используется для сериализации/десериализации, преобразования в доменную сущность [Contract].
/// Позволяет получать и сохранять данные договора, включая связанные имена контрагента и объекта.
///
/// Особенности:
/// - Использует Freezed для иммутабельности и автогенерации методов.
/// - Сериализация через json_serializable с fieldRename.snake.
/// - Поддерживает преобразование из/в доменную сущность [Contract].
@freezed
abstract class ContractModel with _$ContractModel {
  /// Основной конструктор модели договора.
  ///
  /// [id] — идентификатор,
  /// [number] — номер,
  /// [date] — дата начала,
  /// [endDate] — дата окончания,
  /// [contractorId] — id контрагента,
  /// [contractorName] — сокращённое наименование контрагента (подгружается через join),
  /// [amount] — сумма,
  /// [objectId] — id объекта,
  /// [objectName] — наименование объекта (подгружается через join),
  /// [status] — статус,
  /// [createdAt]/[updatedAt] — даты создания/обновления.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory ContractModel({
    required String id,
    required String number,
    @JsonKey(toJson: _dateOnlyToJson) required DateTime date,
    @JsonKey(toJson: _dateOnlyToJson) DateTime? endDate,
    required String contractorId,
    String? contractorName,
    required double amount,
    required String objectId,
    String? objectName,
    @Default(ContractStatus.active) ContractStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ContractModel;

  /// Приватный конструктор для поддержки методов расширения.
  const ContractModel._();

  /// Логгер для отладочной информации.
  static final Logger _logger = Logger();

  /// Создаёт модель из JSON-ответа Supabase.
  ///
  /// Особенность: корректно парсит сокращённое наименование контрагента (contractor.short_name)
  /// и имя объекта (object.name) из join-запроса, с fallback на обычные поля.
  ///
  /// Пример:
  /// ```json
  /// {
  ///   "id": "...",
  ///   "contractor": {"short_name": "ООО Рога"},
  ///   "object": {"name": "Объект 1"},
  ///   ...
  /// }
  /// ```
  factory ContractModel.fromJson(Map<String, dynamic> json) {
    _logger.d('[CONTRACTS][FROM JSON] input: $json');
    // Парсим сокращённое наименование контрагента из join-ответа
    final model = _$ContractModelFromJson({
      ...json,
      'contractor_name': json['contractor']?['short_name'] ?? json['contractor_name'],
      'object_name': json['object']?['name'] ?? json['object_name'],
    });
    _logger.d('[CONTRACTS][FROM JSON] output: $model');
    return model;
  }

  /// Преобразует модель в JSON для API.
  ///
  /// Исключает поля contractor_name и object_name, так как они подгружаются через join.
  Map<String, dynamic> toJson() {
    final json = _$ContractModelToJson(this as _ContractModel);
    json.remove('contractor_name');
    json.remove('object_name');
    _logger.d('[CONTRACTS][TO JSON] output: $json');
    return json;
  }

  /// Создаёт модель из доменной сущности [Contract].
  ///
  /// Используется для сохранения/обновления данных в БД.
  factory ContractModel.fromDomain(Contract contract) => ContractModel(
        id: contract.id,
        number: contract.number,
        date: contract.date,
        endDate: contract.endDate,
        contractorId: contract.contractorId,
        contractorName: contract.contractorName,
        amount: contract.amount,
        objectId: contract.objectId,
        objectName: contract.objectName,
        status: contract.status,
        createdAt: contract.createdAt,
        updatedAt: contract.updatedAt,
      );
  
  /// Преобразует модель в доменную сущность [Contract].
  ///
  /// Используется для передачи данных в слой бизнес-логики.
  Contract toDomain() => Contract(
        id: id,
        number: number,
        date: date,
        endDate: endDate,
        contractorId: contractorId,
        contractorName: contractorName,
        amount: amount,
        objectId: objectId,
        objectName: objectName,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Сериализует дату только в формате YYYY-MM-DD для API.
///
/// Используется для корректной передачи дат в Supabase.
String? _dateOnlyToJson(DateTime? date) => date?.toIso8601String().split('T').first; 