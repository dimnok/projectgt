import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/employee_application.dart';
import 'package:projectgt/features/employees/presentation/providers/employee_applications_provider.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_application_scan_preview.dart';

/// Скачивает подписанный скан заявления на устройство пользователя.
Future<void> downloadEmployeeApplicationScan({
  required BuildContext context,
  required WidgetRef ref,
  required String employeeId,
  required EmployeeApplication application,
}) async {
  final busy = ref.read(
    employeeApplicationBusyIdsProvider(employeeId).notifier,
  );
  if (busy.state.contains(application.id)) return;

  busy.state = {...busy.state, application.id};
  try {
    final bytes = await ref
        .read(employeeApplicationsProvider(employeeId).notifier)
        .downloadScan(application.scanPath);
    await saveFileBytesToUserDevice(
      fileName: application.scanName,
      bytes: bytes,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Ошибка при скачивании: $e',
      kind: AppSnackBarKind.error,
    );
  } finally {
    final n = ref.read(employeeApplicationBusyIdsProvider(employeeId).notifier);
    n.state = {...n.state}..remove(application.id);
  }
}

/// Открывает просмотр подписанного скана (PDF или изображение).
Future<void> viewEmployeeApplicationScan({
  required BuildContext context,
  required WidgetRef ref,
  required String employeeId,
  required EmployeeApplication application,
}) async {
  final busy = ref.read(
    employeeApplicationBusyIdsProvider(employeeId).notifier,
  );
  if (busy.state.contains(application.id)) return;

  busy.state = {...busy.state, application.id};
  try {
    final bytes = await ref
        .read(employeeApplicationsProvider(employeeId).notifier)
        .downloadScan(application.scanPath);
    if (!context.mounted) return;
    await openEmployeeApplicationScanPreview(
      context: context,
      fileName: application.scanName,
      contentType: application.scanType,
      bytes: bytes,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Ошибка при открытии: $e',
      kind: AppSnackBarKind.error,
    );
  } finally {
    final n = ref.read(employeeApplicationBusyIdsProvider(employeeId).notifier);
    n.state = {...n.state}..remove(application.id);
  }
}
