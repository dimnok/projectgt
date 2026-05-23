import 'package:flutter/material.dart';
import '../../../../core/widgets/mobile_atmosphere_backdrop.dart';

/// Заглушка таблицы материалов, пока не выбраны объект и договор.
class MaterialsSelectContextPlaceholder extends StatelessWidget {
  /// Создаёт заглушку.
  const MaterialsSelectContextPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 40,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите объект и договор',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Укажите контекст в фильтрах выше — после этого отобразится реестр материалов.',
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
