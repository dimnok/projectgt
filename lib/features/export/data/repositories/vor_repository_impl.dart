import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/vor_repository.dart';

/// Провайдер репозитория для генерации отчетов ВОР.
final vorRepositoryProvider = Provider<VorRepository>((ref) {
  return VorRepositoryImpl(Supabase.instance.client);
});

/// Реализация репозитория для генерации отчетов ВОР через Supabase Functions.
class VorRepositoryImpl implements VorRepository {
  final SupabaseClient _supabase;

  /// Создает экземпляр репозитория.
  VorRepositoryImpl(this._supabase);

  @override
  Future<Uint8List> downloadVorReport({
    required String objectId,
    required DateTime dateFrom,
    required DateTime dateTo,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
    String? searchQuery,
  }) async {
    return _invokeGenerateFunction(
      functionName: 'generate_vor',
      objectId: objectId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      systemFilters: systemFilters,
      sectionFilters: sectionFilters,
      floorFilters: floorFilters,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Uint8List> downloadVorPdfReport({
    required String objectId,
    required DateTime dateFrom,
    required DateTime dateTo,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
    String? searchQuery,
  }) async {
    return _invokeGenerateFunction(
      functionName: 'generate_vor_pdf',
      objectId: objectId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      systemFilters: systemFilters,
      sectionFilters: sectionFilters,
      floorFilters: floorFilters,
      searchQuery: searchQuery,
    );
  }

  Future<Uint8List> _invokeGenerateFunction({
    required String functionName,
    required String objectId,
    required DateTime dateFrom,
    required DateTime dateTo,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
    String? searchQuery,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        functionName,
        body: {
          'objectId': objectId,
          'dateFrom': dateFrom.toIso8601String(),
          'dateTo': dateTo.toIso8601String(),
          if (systemFilters != null && systemFilters.isNotEmpty)
            'systemFilters': systemFilters,
          if (sectionFilters != null && sectionFilters.isNotEmpty)
            'sectionFilters': sectionFilters,
          if (floorFilters != null && floorFilters.isNotEmpty)
            'floorFilters': floorFilters,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'searchQuery': searchQuery,
        },
      );

      final dynamic data = response.data;

      if (data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      late Map<String, dynamic> jsonResponse;

      if (data is String) {
        jsonResponse = jsonDecode(data);
      } else if (data is Map) {
        jsonResponse = Map<String, dynamic>.from(data);
      } else {
        throw Exception('Неверный формат ответа: ${data.runtimeType}');
      }

      if (jsonResponse.containsKey('error')) {
        throw Exception(jsonResponse['error']);
      }

      if (!jsonResponse.containsKey('file')) {
        throw Exception('Ответ не содержит файл');
      }

      final String base64File = jsonResponse['file'];
      return base64Decode(base64File);
    } catch (e) {
      rethrow;
    }
  }
}
