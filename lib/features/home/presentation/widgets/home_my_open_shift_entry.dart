import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/works/presentation/providers/work_provider.dart';

/// Кнопка на главной: переход к открытой смене текущего пользователя.
///
/// Не отображается, если нет права на «Работы», нет профиля, нет открытой смены
/// или при ошибке/загрузке запроса id (без лишних индикаторов).
class HomeMyOpenShiftEntry extends ConsumerWidget {
  /// Создаёт виджет входа в открытую смену.
  const HomeMyOpenShiftEntry({super.key});

  static const Color _accent = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    if (!permissions.can('works', 'read')) {
      return const SizedBox.shrink();
    }

    final asyncId = ref.watch(myOpenWorkIdProvider);

    return asyncId.when(
      data: (workId) {
        if (workId == null || workId.isEmpty) {
          return const SizedBox.shrink();
        }
        return Semantics(
          button: true,
          label: 'Перейти в мою открытую смену',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SizedBox(
              width: double.infinity,
              child: GTSecondaryButton(
                text: 'Моя открытая смена',
                icon: CupertinoIcons.arrow_right_circle_fill,
                color: _accent,
                onPressed: () {
                  context.pushNamed(
                    'work_details',
                    pathParameters: {'workId': workId},
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
