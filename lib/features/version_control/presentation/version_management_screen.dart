import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/version_control/providers/version_providers.dart';
import 'package:projectgt/domain/entities/app_version.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Экран управления версией приложения (для администраторов).
///
/// Позволяет админам устанавливать минимальную версию и включать принудительное обновление.
class VersionManagementScreen extends ConsumerStatefulWidget {
  /// Создаёт экземпляр [VersionManagementScreen].
  const VersionManagementScreen({super.key});

  @override
  ConsumerState<VersionManagementScreen> createState() =>
      _VersionManagementScreenState();
}

class _VersionManagementScreenState
    extends ConsumerState<VersionManagementScreen> {
  final _minimumVersionController = TextEditingController();
  final _messageController = TextEditingController();
  bool _forceUpdate = false;
  String? _versionId;

  @override
  void dispose() {
    _minimumVersionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Сохраняет изменения версии.
  Future<void> _saveVersion() async {
    final repository = ref.read(versionRepositoryProvider);
    final minimumVersion = _minimumVersionController.text.trim();
    final message = _messageController.text.trim();

    if (minimumVersion.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Минимальная версия не может быть пустой')),
      );
      return;
    }

    // Проверка формата версии (major.minor.patch)
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionRegex.hasMatch(minimumVersion)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный формат версии. Используйте формат: 1.0.0'),
        ),
      );
      return;
    }

    if (_versionId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: ID версии не найден')),
      );
      return;
    }

    try {
      await repository.updateVersion(
        id: _versionId!,
        minimumVersion: minimumVersion,
        forceUpdate: _forceUpdate,
        updateMessage: message.isEmpty ? null : message,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Версия успешно обновлена'),
          backgroundColor: Colors.green,
        ),
      );

      // Обновляем информацию
      ref.invalidate(currentVersionInfoProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Инициализирует контроллеры данными из версии.
  void _initializeControllers(AppVersion version) {
    if (_versionId != version.id) {
      _versionId = version.id;
      _minimumVersionController.text = version.minimumVersion;
      _messageController.text = version.updateMessage ?? '';
      _forceUpdate = version.forceUpdate;
    }
  }

  /// Форматирует дату и время для отображения.
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final versionAsync = ref.watch(currentVersionInfoProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7) // iOS светлый grouped background
          : const Color(0xFF1C1C1E), // iOS темный grouped background
      appBar: const AppBarWidget(title: 'Управление версией'),
      drawer: const AppDrawer(activeRoute: AppRoute.versionManagement),
      body: versionAsync.when(
        data: (version) {
          if (version == null) {
            return const Center(
              child: Text('Нет данных о версии'),
            );
          }

          _initializeControllers(version);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentVersionInfoProvider);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 800 : double.infinity,
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Информация о текущей версии
                      _AppleMenuGroup(
                        children: [
                          _AppleMenuItem(
                            icon: Icons.info_outline_rounded,
                            iconColor: Colors.blue,
                            title: 'Текущая версия приложения',
                            subtitle: 'iOS • Android • Web',
                            trailing: Text(
                              version.currentVersion,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            showChevron: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Все настройки в одной группе
                      _AppleMenuGroup(
                        children: [
                          // Минимальная версия
                          _SettingsField(
                            label: 'Минимальная версия',
                            child: TextField(
                              controller: _minimumVersionController,
                              decoration: InputDecoration(
                                hintText: '1.0.0',
                                helperText: 'Формат: 1.2.3',
                                helperStyle: theme.textTheme.bodySmall,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          // Сообщение
                          _SettingsField(
                            label: 'Сообщение для пользователей',
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText:
                                    'Обновите приложение до последней версии',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ),
                          // Принудительное обновление
                          _SwitchSettingsItem(
                            icon: _forceUpdate
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            iconColor: _forceUpdate ? Colors.red : Colors.green,
                            title: 'Принудительное обновление',
                            subtitle: _forceUpdate
                                ? 'Блокировать старые версии'
                                : 'Разрешить старые версии',
                            value: _forceUpdate,
                            onChanged: (value) {
                              setState(() {
                                _forceUpdate = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Компактное предупреждение
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Изменения применяются мгновенно',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Кнопка сохранения
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saveVersion,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Сохранить изменения',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Информация о последнем обновлении
                      if (version.updatedAt != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Обновлено: ${_formatDateTime(version.updatedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки данных',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(currentVersionInfoProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Группа элементов меню в стиле Apple Settings.
///
/// Объединяет несколько [_AppleMenuItem] в одну карточку с закругленными углами.
class _AppleMenuGroup extends StatelessWidget {
  /// Список элементов меню внутри группы.
  final List<Widget> children;

  /// Создаёт группу элементов меню.
  const _AppleMenuGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  /// Добавляет разделители между элементами списка.
  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Иконка в цветном квадратике для элементов меню.
class _MenuIcon extends StatelessWidget {
  /// Иконка.
  final IconData icon;

  /// Цвет иконки.
  final Color color;

  /// Создаёт иконку в квадратике.
  const _MenuIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 18,
      ),
    );
  }
}

/// Элемент меню в стиле Apple Settings.
///
/// Отображает иконку, заголовок, опциональный подзаголовок.
class _AppleMenuItem extends StatelessWidget {
  /// Иконка элемента.
  final IconData icon;

  /// Цвет иконки.
  final Color iconColor;

  /// Основной текст элемента.
  final String title;

  /// Дополнительный текст под заголовком (опционально).
  final String? subtitle;

  /// Виджет справа (опционально).
  final Widget? trailing;

  /// Показывать ли стрелку вправо.
  final bool showChevron;

  /// Создаёт элемент меню в стиле Apple.
  const _AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _MenuIcon(icon: icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );
  }
}

/// Поле настроек с заголовком и контентом.
class _SettingsField extends StatelessWidget {
  /// Заголовок поля.
  final String label;

  /// Контент поля (например, TextField).
  final Widget child;

  /// Создаёт поле настроек.
  const _SettingsField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Элемент настроек с переключателем (Switch).
class _SwitchSettingsItem extends StatelessWidget {
  /// Иконка элемента.
  final IconData icon;

  /// Цвет иконки.
  final Color iconColor;

  /// Основной текст элемента.
  final String title;

  /// Дополнительный текст под заголовком.
  final String subtitle;

  /// Значение переключателя.
  final bool value;

  /// Коллбэк при изменении значения.
  final ValueChanged<bool> onChanged;

  /// Создаёт элемент с переключателем.
  const _SwitchSettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _MenuIcon(icon: icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
