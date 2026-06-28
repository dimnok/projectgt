import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/employee_application.dart';

part 'employee_application_model.freezed.dart';
part 'employee_application_model.g.dart';

/// DTO заявления сотрудника для PostgREST.
@freezed
abstract class EmployeeApplicationModel with _$EmployeeApplicationModel {
  const EmployeeApplicationModel._();

  /// Создаёт модель из JSON ответа Supabase.
  const factory EmployeeApplicationModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'employee_id') required String employeeId,
    @JsonKey(name: 'application_type') required String applicationType,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'duration_days') required int durationDays,
    @JsonKey(name: 'scan_name') required String scanName,
    @JsonKey(name: 'scan_path') required String scanPath,
    @JsonKey(name: 'scan_size') required int scanSize,
    @JsonKey(name: 'scan_type') required String scanType,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'creator') Map<String, dynamic>? creator,
  }) = _EmployeeApplicationModel;

  /// Парсит JSON PostgREST.
  factory EmployeeApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeApplicationModelFromJson(json);

  /// Преобразует модель в доменную сущность.
  EmployeeApplication toEntity() {
    final creatorName = creator?['full_name'] as String?;
    return EmployeeApplication(
      id: id,
      companyId: companyId,
      employeeId: employeeId,
      applicationType:
          EmployeeApplicationTypeX.fromDbValue(applicationType),
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      scanName: scanName,
      scanPath: scanPath,
      scanSize: scanSize,
      scanType: scanType,
      createdBy: createdBy,
      createdByName: creatorName?.trim().isNotEmpty == true
          ? creatorName!.trim()
          : null,
      createdAt: createdAt,
    );
  }
}
