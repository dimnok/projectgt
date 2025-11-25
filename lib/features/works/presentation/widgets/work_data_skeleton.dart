import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

class WorkDataSkeleton extends StatelessWidget {
  const WorkDataSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = !ResponsiveUtils.isDesktop(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
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
              const SizedBox(height: 16),

              // Distribution Card Placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),

              // Photo View Placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 1200.ms, color: isDark ? Colors.white10 : Colors.white54),
        ),
      ),
    );
  }
}
