import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectgt/data/datasources/employee_application_data_source.dart';
import 'package:projectgt/data/models/employee_application_model.dart';
import 'package:projectgt/domain/entities/employee_application.dart';

/// Реализация [EmployeeApplicationDataSource] через Supabase.
class SupabaseEmployeeApplicationDataSource
    implements EmployeeApplicationDataSource {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  static const _table = 'employee_applications';
  static const _bucket = 'employee_applications';

  /// Создаёт datasource.
  SupabaseEmployeeApplicationDataSource(this.client, this.activeCompanyId);

  @override
  Future<List<EmployeeApplicationModel>> getByEmployee(
    String employeeId,
  ) async {
    final response = await client
        .from(_table)
        .select(
          '*, creator:profiles!employee_applications_created_by_fkey(full_name)',
        )
        .eq('employee_id', employeeId)
        .eq('company_id', activeCompanyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => EmployeeApplicationModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  @override
  Future<EmployeeApplicationModel> uploadSignedScan({
    required String employeeId,
    required EmployeeApplicationType applicationType,
    required DateTime startDate,
    DateTime? endDate,
    required int durationDays,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required String createdBy,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    final storagePath =
        '$activeCompanyId/$employeeId/${applicationType.dbValue}/${timestamp}_$safeName';

    try {
      await client.storage.from(_bucket).uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );

      final row = {
        'company_id': activeCompanyId,
        'employee_id': employeeId,
        'application_type': applicationType.dbValue,
        'start_date': _dateOnly(startDate),
        'end_date': endDate != null ? _dateOnly(endDate) : null,
        'duration_days': durationDays,
        'scan_name': fileName,
        'scan_path': storagePath,
        'scan_size': bytes.length,
        'scan_type': contentType,
        'created_by': createdBy,
      };

      final response = await client
          .from(_table)
          .insert(row)
          .select(
            '*, creator:profiles!employee_applications_created_by_fkey(full_name)',
          )
          .single();

      return EmployeeApplicationModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      try {
        await client.storage.from(_bucket).remove([storagePath]);
      } catch (_) {
        // best-effort cleanup
      }
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadScan(String scanPath) async {
    return client.storage.from(_bucket).download(scanPath);
  }

  @override
  Future<void> delete(String applicationId, String scanPath) async {
    await client
        .from(_table)
        .delete()
        .eq('id', applicationId)
        .eq('company_id', activeCompanyId);

    await client.storage.from(_bucket).remove([scanPath]);
  }

  String _dateOnly(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }
}
