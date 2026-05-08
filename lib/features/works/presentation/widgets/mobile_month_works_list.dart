import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/presentation/widgets/mobile_work_card.dart';
import 'package:projectgt/presentation/providers/profiles_cache_provider.dart';

/// Виджет списка смен для мобильной версии (Box-версия для анимации).
class MobileMonthWorksList extends ConsumerWidget {
  /// Группа смен за месяц.
  final MonthGroup group;

  /// Callback при выборе смены.
  final Function(Work work) onWorkSelected;

  /// Callback для загрузки следующей порции данных.
  final VoidCallback onLoadMore;

  /// Создает экземпляр [MobileMonthWorksList].
  const MobileMonthWorksList({
    super.key,
    required this.group,
    required this.onWorkSelected,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works = group.works;
    final cardStyle = MobileAtmosphereCardStyle.fromAppearance(
      MobileAtmosphereAppearance.of(context),
    );

    if (works == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (works.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Нет смен в этом месяце',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final hasMore = works.length < group.worksCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < works.length; i++)
            _buildWorkItem(context, ref, cardStyle, works[i], i),
          if (hasMore) _LoaderItem(onLoadMore: onLoadMore),
        ],
      ),
    );
  }

  Widget _buildWorkItem(
    BuildContext context,
    WidgetRef ref,
    MobileAtmosphereCardStyle cardStyle,
    Work work,
    int index,
  ) {
    // Получаем название объекта
    final objectName = ref
            .watch(objectProvider)
            .objects
            .where((o) => o.id == work.objectId)
            .map((o) => o.name)
            .firstOrNull ??
        work.objectId;

    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = _getWorkStatusInfo(work.status, scheme);

    final profileAsync = ref.watch(userProfileProvider(work.openedBy));
    final String createdBy = profileAsync.when(
      data: (profile) =>
          profile?.shortName ?? 'ID: ${work.openedBy.substring(0, 4)}...',
      loading: () => '...',
      error: (_, __) => 'ID: ${work.openedBy.substring(0, 4)}...',
    );

    // Анимация: чередование слева/справа
    final isLeft = index % 2 == 0;
    final double offsetX = isLeft ? -50 : 50;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MobileWorkCard(
        work: work,
        listMonth: group.month,
        listIndex: index,
        style: cardStyle,
        objectName: objectName,
        createdBy: createdBy,
        onTap: () {
          onWorkSelected(work);
        },
        statusColor: statusColor,
        statusSemanticsLabel: statusLabel,
      ),
    )
        .animate()
        .fade(duration: 400.ms, delay: (index * 50).ms)
        .moveX(begin: offsetX, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  (String, Color) _getWorkStatusInfo(String status, ColorScheme scheme) {
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', scheme.primary);
      case 'closed':
        return ('Закрыта', scheme.error);
      default:
        return ('Неизвестно', scheme.onSurfaceVariant);
    }
  }
}

class _LoaderItem extends StatefulWidget {
  final VoidCallback onLoadMore;

  const _LoaderItem({required this.onLoadMore});

  @override
  State<_LoaderItem> createState() => _LoaderItemState();
}

class _LoaderItemState extends State<_LoaderItem> {
  @override
  void initState() {
    super.initState();
    // Запускаем загрузку при появлении
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}
