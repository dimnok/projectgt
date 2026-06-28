import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/employee_application.dart';
import 'package:projectgt/features/employees/presentation/providers/employee_applications_provider.dart';

/// MIME-тип по расширению файла.
String employeeApplicationContentTypeFromFileName(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  return switch (ext) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    _ => 'application/octet-stream',
  };
}

/// Открывает выбор файла и загружает подписанный скан заявления.
Future<void> uploadEmployeeApplicationSignedScan({
  required BuildContext context,
  required WidgetRef ref,
  required String employeeId,
  required EmployeeApplicationType applicationType,
  required DateTime startDate,
  DateTime? endDate,
  required int durationDays,
}) async {
  try {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Скан заявления',
          extensions: ['pdf', 'jpg', 'jpeg', 'png'],
        ),
      ],
    );
    if (file == null) return;

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Загружаем скан…',
      kind: AppSnackBarKind.info,
    );

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    await ref
        .read(employeeApplicationsProvider(employeeId).notifier)
        .uploadSignedScan(
          applicationType: applicationType,
          startDate: startDate,
          endDate: endDate,
          durationDays: durationDays,
          bytes: bytes,
          fileName: file.name,
          contentType: employeeApplicationContentTypeFromFileName(file.name),
        );

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Скан заявления загружен',
      kind: AppSnackBarKind.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Ошибка загрузки: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
