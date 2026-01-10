import 'package:flutter/material.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_row_item_mobile.dart';

/// Мобильная версия списка объектов.
class ObjectsListMobileView extends StatelessWidget {
  /// Состояние объектов.
  final ObjectState state;

  /// Список объектов для отображения.
  final List<ObjectEntity> objects;

  /// Колбэк обновления.
  final Future<void> Function() onRefresh;

  /// Колбэк при нажатии на объект.
  final Function(ObjectEntity) onTap;

  /// Контроллер скролла.
  final ScrollController scrollController;

  /// Создает мобильную версию списка объектов.
  const ObjectsListMobileView({
    super.key,
    required this.state,
    required this.objects,
    required this.onRefresh,
    required this.onTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == ObjectStatus.loading && objects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ObjectStatus.error && objects.isEmpty) {
      return Center(child: Text(state.errorMessage ?? 'Ошибка'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Всего объектов: ${objects.length}',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: objects.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Text(
                            'Список объектов пуст',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      final object = objects[index];
                      return ObjectRowItemMobile(
                        object: object,
                        onTap: () => onTap(object),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

