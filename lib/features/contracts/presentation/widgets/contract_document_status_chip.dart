import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';

/// Компактный chip статуса документа договора (документооборот).
///
/// Пастельные акценты, без «кислотных» цветов; читаемо на desktop.
class ContractDocumentStatusChip extends StatelessWidget {
  /// Статус для отображения.
  final ContractDocumentStatus status;

  /// Создаёт chip.
  const ContractDocumentStatusChip({super.key, required this.status});

  static Color _foreground(
    ContractDocumentStatus s,
    ColorScheme scheme,
    Brightness brightness,
  ) {
    final on = scheme.onSurface;
    switch (s) {
      case ContractDocumentStatus.draft:
        return on.withValues(alpha: brightness == Brightness.dark ? 0.72 : 0.62);
      case ContractDocumentStatus.pendingApproval:
        return on.withValues(alpha: brightness == Brightness.dark ? 0.88 : 0.72);
      case ContractDocumentStatus.approved:
        return on.withValues(alpha: brightness == Brightness.dark ? 0.9 : 0.72);
      case ContractDocumentStatus.signed:
        return on.withValues(alpha: brightness == Brightness.dark ? 0.9 : 0.72);
      case ContractDocumentStatus.rejected:
        return on.withValues(alpha: brightness == Brightness.dark ? 0.9 : 0.72);
      case ContractDocumentStatus.obsolete:
        return on.withValues(alpha: brightness == Brightness.dark ? 0.65 : 0.55);
    }
  }

  static Color _background(
    ContractDocumentStatus s,
    ColorScheme scheme,
    Brightness brightness,
  ) {
    final base = scheme.surface;
    switch (s) {
      case ContractDocumentStatus.draft:
        return Color.alphaBlend(
          scheme.onSurface.withValues(alpha: brightness == Brightness.dark ? 0.14 : 0.07),
          base,
        );
      case ContractDocumentStatus.pendingApproval:
        return Color.alphaBlend(
          const Color(0xFFE8A838).withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.16),
          base,
        );
      case ContractDocumentStatus.approved:
        return Color.alphaBlend(
          const Color(0xFF5B9BD5).withValues(alpha: brightness == Brightness.dark ? 0.24 : 0.14),
          base,
        );
      case ContractDocumentStatus.signed:
        return Color.alphaBlend(
          const Color(0xFF4CAF50).withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.13),
          base,
        );
      case ContractDocumentStatus.rejected:
        return Color.alphaBlend(
          const Color(0xFFE57373).withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.14),
          base,
        );
      case ContractDocumentStatus.obsolete:
        return Color.alphaBlend(
          scheme.onSurface.withValues(alpha: brightness == Brightness.dark ? 0.12 : 0.06),
          base,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final fg = _foreground(status, scheme, brightness);
    final bg = _background(status, scheme, brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Text(
        status.ruLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
          height: 1.15,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
