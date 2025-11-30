import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// Экран настроек пользователя.
class SettingsScreen extends ConsumerWidget {
  /// Создаёт экран настроек.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppBarWidget(
        title: 'Настройки',
        leading: BackButton(),
      ),
      body: ContentConstrainedBox(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Внешний вид',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            AppleMenuGroup(
              children: [
                // Выбор шрифта
                AppleMenuItem(
                  icon: CupertinoIcons.textformat,
                  iconColor: CupertinoColors.systemBlue,
                  title: 'Шрифт',
                  subtitle: settings.fontFamily,
                  onTap: () {
                    _showFontPicker(context, settings.fontFamily, notifier);
                  },
                ),
                // Размер шрифта
                AppleMenuItem(
                  icon: CupertinoIcons.text_badge_plus,
                  iconColor: CupertinoColors.systemGreen,
                  title: 'Размер текста',
                  subtitle: '${(settings.textScale * 100).round()}%',
                  onTap: () {
                    _showTextScalePicker(context, settings.textScale, notifier);
                  },
                ),
                // Тема оформления
                AppleMenuItem(
                  icon: CupertinoIcons.brightness,
                  iconColor: CupertinoColors.systemPurple,
                  title: 'Тема',
                  subtitle: _getThemeModeName(settings.themeMode),
                  onTap: () {
                    _showThemeModePicker(context, settings.themeMode, notifier);
                  },
                ),
                // Цветовая схема
                AppleMenuItem(
                  icon: CupertinoIcons.paintbrush,
                  iconColor: CupertinoColors.systemOrange,
                  title: 'Цветовая схема',
                  subtitle: _getSchemeName(settings.scheme),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: settings.scheme == null
                          ? theme.colorScheme.onSurface
                          : FlexColor.schemes[settings.scheme]!.light.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showSchemePicker(context, settings.scheme, notifier);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSchemeName(FlexScheme? scheme) {
    if (scheme == null) return 'Монохром (Default)';
    return FlexColor.schemes[scheme]?.name ?? scheme.name;
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Системная';
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Тёмная';
    }
  }

  void _showFontPicker(BuildContext context, String currentFont,
      ThemeSettingsNotifier notifier) {
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    Widget buildContent(BuildContext ctx) {
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: kAvailableFonts.map((font) {
          final isSelected = font == currentFont;
          return ListTile(
            title: Text(font),
            trailing: isSelected
                ? Icon(CupertinoIcons.check_mark,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              notifier.setFontFamily(font);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Выберите шрифт',
            footer: GTPrimaryButton(
              text: 'Отмена',
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
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Выберите шрифт',
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: buildContent(context),
        ),
      );
    }
  }

  void _showTextScalePicker(BuildContext context, double currentScale,
      ThemeSettingsNotifier notifier) {
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Размер текста',
            footer: GTPrimaryButton(
              text: 'Готово',
              onPressed: () => Navigator.of(context).pop(),
            ),
            child: _TextScalePickerContent(
              initialScale: currentScale,
              notifier: notifier,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Размер текста',
          footer: GTPrimaryButton(
            text: 'Готово',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: _TextScalePickerContent(
            initialScale: currentScale,
            notifier: notifier,
          ),
        ),
      );
    }
  }

  void _showThemeModePicker(BuildContext context, ThemeMode currentMode,
      ThemeSettingsNotifier notifier) {
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    Widget buildContent(BuildContext ctx) {
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: const Icon(CupertinoIcons.settings),
            title: const Text('Системная'),
            trailing: currentMode == ThemeMode.system
                ? Icon(CupertinoIcons.check_mark,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              notifier.setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.sun_max),
            title: const Text('Светлая'),
            trailing: currentMode == ThemeMode.light
                ? Icon(CupertinoIcons.check_mark,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              notifier.setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.moon),
            title: const Text('Тёмная'),
            trailing: currentMode == ThemeMode.dark
                ? Icon(CupertinoIcons.check_mark,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              notifier.setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
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
            title: 'Тема оформления',
            footer: GTPrimaryButton(
              text: 'Отмена',
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
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Тема оформления',
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: buildContent(context),
        ),
      );
    }
  }

  void _showSchemePicker(BuildContext context, FlexScheme? currentScheme,
      ThemeSettingsNotifier notifier) {
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    // Список схем для отображения (можно отфильтровать)
    final schemes = [
      null, // Default Monochrome
      ...FlexScheme.values.where((s) => s != FlexScheme.custom),
    ];

    Widget buildContent(BuildContext ctx) {
      return ListView.builder(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: schemes.length,
        itemBuilder: (context, index) {
          final scheme = schemes[index];
          final isSelected = scheme == currentScheme;

          final String name = scheme == null
              ? 'Монохром (Default)'
              : (FlexColor.schemes[scheme]?.name ?? scheme.name);

          final Color color = scheme == null
              ? Theme.of(context).colorScheme.onSurface
              : FlexColor.schemes[scheme]!.light.primary;

          return ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            title: Text(name),
            trailing: isSelected
                ? Icon(CupertinoIcons.check_mark,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              notifier.setScheme(scheme);
              Navigator.pop(ctx);
            },
          );
        },
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Цветовая схема',
            footer: GTPrimaryButton(
              text: 'Отмена',
              onPressed: () => Navigator.of(context).pop(),
            ),
            child: SizedBox(
              height: 400,
              child: buildContent(context),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Цветовая схема',
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: buildContent(context),
        ),
      );
    }
  }
}

/// Отдельный StatefulWidget для управления слайдером внутри BottomSheet
class _TextScalePickerContent extends StatefulWidget {
  final double initialScale;
  final ThemeSettingsNotifier notifier;

  const _TextScalePickerContent({
    required this.initialScale,
    required this.notifier,
  });

  @override
  State<_TextScalePickerContent> createState() =>
      _TextScalePickerContentState();
}

class _TextScalePickerContentState extends State<_TextScalePickerContent> {
  late double _currentScale;

  @override
  void initState() {
    super.initState();
    _currentScale = widget.initialScale;
  }

  void _updateScale(double newScale) {
    // Ограничиваем значения
    if (newScale < 0.8) newScale = 0.8;
    if (newScale > 1.4) newScale = 1.4;

    // Округляем до 1 знака после запятой (шаг 0.1)
    newScale = (newScale * 10).round() / 10;

    if ((_currentScale - newScale).abs() > 0.01) {
      setState(() {
        _currentScale = newScale;
      });
      widget.notifier.setTextScale(newScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.textformat_size, size: 16),
                onPressed: () => _updateScale(_currentScale - 0.1),
                tooltip: 'Уменьшить',
              ),
              Expanded(
                child: CupertinoSlider(
                  value: _currentScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  onChanged: (value) {
                    setState(() {
                      _currentScale = value;
                    });
                    widget.notifier.setTextScale(value);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.textformat_size, size: 32),
                onPressed: () => _updateScale(_currentScale + 0.1),
                tooltip: 'Увеличить',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${(_currentScale * 100).round()}%',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
