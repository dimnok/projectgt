import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/presentation/providers/profiles_cache_provider.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/works/presentation/widgets/mobile_work_card.dart';

/// Виджет списка смен для мобильной версии (Box-версия для анимации).
class MobileMonthWorksList extends ConsumerWidget {
  final MonthGroup group;
  final Function(Work work) onWorkSelected;
  final VoidCallback onLoadMore;

  const MobileMonthWorksList({
    super.key,
    required this.group,
    required this.onWorkSelected,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works = group.works;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < works.length; i++)
          _buildWorkItem(context, ref, works[i], i),
        if (hasMore) _LoaderItem(onLoadMore: onLoadMore),
      ],
    );
  }

  Widget _buildWorkItem(
      BuildContext context, WidgetRef ref, Work work, int index) {
    // Получаем название объекта
    final objectName = ref
            .watch(objectProvider)
            .objects
            .where((o) => o.id == work.objectId)
            .map((o) => o.name)
            .firstOrNull ??
        work.objectId;

    final (_, statusColor) = _getWorkStatusInfo(work.status);

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

    return MobileWorkCard(
      work: work,
      objectName: objectName,
      createdBy: createdBy,
      onTap: () {
        onWorkSelected(work);
      },
      statusColor: statusColor,
    )
        .animate()
        .fade(duration: 400.ms, delay: (index * 50).ms)
        .moveX(begin: offsetX, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  (String, Color) _getWorkStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', Colors.green);
      case 'closed':
        return ('Закрыта', Colors.red);
      default:
        return ('Неизвестно', Colors.grey);
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
