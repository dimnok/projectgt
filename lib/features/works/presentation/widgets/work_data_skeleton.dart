import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/works/presentation/widgets/work_detail_data_spacing.dart';

/// Скелетон для экрана данных о работах.
///
/// Отображает заглушку загрузки с анимацией shimmer, имитирующую структуру
/// карточек статистики, распределения и фотографий.
class WorkDataSkeleton extends StatelessWidget {
  /// Создает экземпляр скелетона.
  const WorkDataSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = !ResponsiveUtils.isDesktop(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);

    final phone = ResponsiveUtils.isMobile(context);
    final hPad = phone ? WorkDetailDataSpacing.mobileScrollHorizontal : 16.0;
    final blockGap = phone ? WorkDetailDataSpacing.mobileBetweenCards : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, hPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child:
              Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isMobile) ...[
                        Container(
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],

                      // Stats Card Placeholder
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      SizedBox(height: blockGap),

                      // Distribution Card Placeholder
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      SizedBox(height: blockGap),

                      // Photo View Placeholder
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1200.ms,
                    color: isDark ? Colors.white10 : Colors.white54,
                  ),
        ),
      ),
    );
  }
}
