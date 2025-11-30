import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

/// Экран "Выданное имущество".
///
/// Показывает список категорий имущества, выданного сотруднику:
/// - СИЗы (Средства Индивидуальной Защиты)
/// - Инструмент
/// - Оргтехника
/// - Спецодежда
/// - Прочее
///
/// Реализован в стиле Apple Settings с группировкой элементов.
class PropertyScreen extends StatelessWidget {
  /// Создаёт экран выданного имущества.
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppBarWidget(
        title: 'Выданное имущество',
        leading: BackButton(),
      ),
      body: ContentConstrainedBox(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информационное сообщение
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Имущество, числящееся за вами. При увольнении необходимо сдать.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Заголовок
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: Text(
                  'КАТЕГОРИИ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Группа элементов
              AppleMenuGroup(
                children: [
                  AppleMenuItem(
                    icon: CupertinoIcons.shield,
                    iconColor: CupertinoColors.systemOrange,
                    title: 'Средства индивидуальной защиты (СИЗы)',
                    subtitle:
                        'Каски, перчатки, респираторы, системы безопасности',
                    onTap: () => _showPropertyInfo(
                      context: context,
                      title: 'СИЗы',
                      content: _getSizContent(),
                    ),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.hammer,
                    iconColor: CupertinoColors.systemRed,
                    title: 'Инструмент',
                    subtitle:
                        'Электроинструмент, ручной инструмент, измерительные приборы',
                    onTap: () => _showPropertyInfo(
                      context: context,
                      title: 'Инструмент',
                      content: _getToolsContent(),
                    ),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.desktopcomputer,
                    iconColor: CupertinoColors.systemBlue,
                    title: 'Оргтехника',
                    subtitle: 'Ноутбуки, телефоны, планшеты',
                    onTap: () => _showPropertyInfo(
                      context: context,
                      title: 'Оргтехника',
                      content: _getTechContent(),
                    ),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.person_crop_square,
                    iconColor: CupertinoColors.systemIndigo,
                    title: 'Спецодежда',
                    subtitle: 'Куртки, комбинезоны, обувь',
                    onTap: () => _showPropertyInfo(
                      context: context,
                      title: 'Спецодежда',
                      content: _getClothesContent(),
                    ),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.cube_box,
                    iconColor: CupertinoColors.systemGrey,
                    title: 'Прочее',
                    subtitle: 'Мебель, ключи, пропуска',
                    onTap: () => _showPropertyInfo(
                      context: context,
                      title: 'Прочее',
                      content: _getOtherContent(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Если вы обнаружили расхождение в списке имущества, обратитесь к материально ответственному лицу.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPropertyInfo({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    Widget buildContent(BuildContext ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (content.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.cube_box,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Список пуст',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
        ],
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: title,
            footer: GTPrimaryButton(
              text: 'Закрыть',
              onPressed: () => Navigator.of(context).pop(),
            ),
            child: buildContent(context),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 640),
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: title,
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: buildContent(context),
        ),
      );
    }
  }

  // Заглушки для контента (в будущем будут браться из БД)
  String _getSizContent() {
    return '''
1. Каска защитная "РОСОМЗ" (белая) — 1 шт. (выдано: 12.01.2024)
2. Жилет сигнальный (оранжевый) — 1 шт. (выдано: 12.01.2024)
3. Очки защитные открытые — 1 шт. (выдано: 12.01.2024)
4. Перчатки "ХБ с ПВХ" — 5 пар (выдано: 01.10.2024)
    ''';
  }

  String _getToolsContent() {
    return '''
1. Шуруповерт Makita DDF453 — 1 шт. (инв. №10234)
2. Набор бит Bosch (32 предмета) — 1 шт.
3. Рулетка 5м Stanley — 1 шт.
4. Уровень строительный 60см — 1 шт.
    ''';
  }

  String _getTechContent() {
    return ''; // Пусто
  }

  String _getClothesContent() {
    return '''
1. Костюм "Профессионал" (куртка + полукомбинезон) — 1 компл.
2. Ботинки рабочие с мет. подноском — 1 пара
    ''';
  }

  String _getOtherContent() {
    return '''
1. Пропуск на объект "ЖК Солнечный" — 1 шт.
    ''';
  }
}
