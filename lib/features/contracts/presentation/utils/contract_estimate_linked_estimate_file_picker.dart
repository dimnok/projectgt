import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Результат [pickContractLinkedEstimateFile].
///
/// [isCanceled] — диалог закрыт без выбора.
/// [createNewEstimate] — пользователь выбрал «Новая смета» (дальше LC/ДС с пустым заголовком).
/// Иначе выбрана смета [selectedFile].
class PickContractLinkedEstimateResult {
  /// Выбранная смета; null при [createNewEstimate] или отмене.
  final EstimateFile? selectedFile;

  /// Открыть сценарий создания новой сметы в рамках LC/ДС.
  final bool createNewEstimate;

  const PickContractLinkedEstimateResult._({
    this.selectedFile,
    this.createNewEstimate = false,
  });

  /// Закрыто без действия.
  bool get isCanceled => selectedFile == null && !createNewEstimate;

  /// Выбран пункт списка.
  factory PickContractLinkedEstimateResult.fromFile(EstimateFile file) {
    return PickContractLinkedEstimateResult._(selectedFile: file);
  }

  /// Пользователь нажал «Новая смета».
  factory PickContractLinkedEstimateResult.newEstimate() {
    return const PickContractLinkedEstimateResult._(createNewEstimate: true);
  }
}

/// Текст подписи «Объект: …» для строки сметы.
String? _objectSubtitleLine(
  EstimateFile f,
  Map<String, String>? objectNamesById,
) {
  final id = f.objectId?.trim();
  if (id == null || id.isEmpty) return null;
  final name = objectNamesById?[id]?.trim();
  if (name != null && name.isNotEmpty) {
    return 'Объект: $name';
  }
  return 'Объект: $id';
}

/// Диалог выбора сметы, привязанной к договору (несколько заголовков на один договор).
///
/// Использует [Dialog] с явной шириной, чтобы не сочетать [AlertDialog]/IntrinsicWidth
/// с виджетами, завязанными на [LayoutBuilder] (например [ListTile] в M3).
///
/// Вёрстка ориентирована на UX: зоны нажатия не меньше ~52dp, зазор между интерактивными
/// элементами 10–16dp, подписи и вторичный текст с пониженной контрастностью.
///
/// [dialogTitle] — заголовок окна (например для ДС или для выгрузки Excel).
/// [objectNamesById] — отображаемые названия объектов по `object_id` (UUID не показываем,
/// если имя известно).
/// [showNewEstimateButton] — кнопка «Новая смета» (для выгрузки Excel обычно false).
Future<PickContractLinkedEstimateResult?> pickContractLinkedEstimateFile(
  BuildContext context,
  List<EstimateFile> files, {
  String dialogTitle = 'Смета для доп. соглашения',
  Map<String, String>? objectNamesById,
  bool showNewEstimateButton = true,
}) {
  return showDialog<PickContractLinkedEstimateResult>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
      final listHeight = (MediaQuery.sizeOf(ctx).height * 0.42).clamp(220.0, 420.0);
      final outerRadius = BorderRadius.circular(16);
      final hint = showNewEstimateButton
          ? 'Выберите смету в списке или нажмите «Новая смета».'
          : 'Выберите смету для выгрузки файла.';

      return Semantics(
        namesRoute: true,
        label: dialogTitle,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: outerRadius,
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.22)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500, maxHeight: maxH),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dialogTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: listHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.18),
                        ),
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.28,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: files.length,
                          itemBuilder: (itemCtx, index) {
                            final f = files[index];
                            final subtitle = _objectSubtitleLine(
                              f,
                              objectNamesById,
                            );
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < files.length - 1 ? 10 : 0,
                              ),
                              child: _PickEstimateRow(
                                estimateTitle: f.estimateTitle,
                                subtitle: subtitle,
                                onTap: () => Navigator.of(ctx).pop(
                                  PickContractLinkedEstimateResult.fromFile(f),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GTTextButton(
                        text: 'Отмена',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      const Spacer(),
                      if (showNewEstimateButton)
                        PermissionGuard(
                          module: 'estimates',
                          permission: 'import',
                          child: GTSecondaryButton(
                            text: 'Новая смета',
                            icon: CupertinoIcons.add_circled,
                            onPressed: () => Navigator.of(ctx).pop(
                              PickContractLinkedEstimateResult.newEstimate(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Строка выбора сметы: явная зона нажатия, без [ListTile] (совместимость с layout).
class _PickEstimateRow extends StatelessWidget {
  /// Заголовок сметы.
  final String estimateTitle;

  /// Подпись «Объект: …» или null.
  final String? subtitle;

  /// Выбор строки.
  final VoidCallback onTap;

  /// Создаёт строку выбора сметы.
  const _PickEstimateRow({
    required this.estimateTitle,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(12);
    final sub = subtitle;

    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Semantics(
          button: true,
          label: sub != null && sub.isNotEmpty
              ? '$estimateTitle, $sub'
              : estimateTitle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estimateTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      sub,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
