import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:projectgt/features/version_control/providers/version_providers.dart';
import 'package:projectgt/domain/entities/app_version.dart';
import 'package:projectgt/core/constants/app_constants.dart';
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
  String _deviceVersion = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceVersion();
  }

  @override
  void dispose() {
    _minimumVersionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Загружает информацию о версии устройства.
  Future<void> _loadDeviceVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (mounted) {
        setState(() {
          // Проверяем, что version не пустой
          if (packageInfo.version.isNotEmpty) {
            _deviceVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
          } else {
            _deviceVersion = 'Build ${packageInfo.buildNumber}';
          }
        });
      }
    } catch (e) {
      // Тихий fallback на версию из AppConstants для Web
      if (mounted) {
        setState(() {
          _deviceVersion = AppConstants.appVersion;
        });
      }
    }
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
      backgroundColor: theme.colorScheme.surface,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок и описание
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Контроль версий приложения',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Управляйте минимальной версией приложения для всех платформ (iOS, Android, Web).',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Предупреждение
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Изменения применяются мгновенно через Realtime. '
                                'Пользователи со старыми версиями будут заблокированы.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Карточка управления версией
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.system_update_alt_rounded,
                                      size: 28,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Единая версия для всех платформ',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.apple_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.android_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.language_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'iOS • Android • Web',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 24),

                              // Текущие версии
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      'Текущая версия приложения:',
                                      version.currentVersion,
                                      theme,
                                      Icons.check_circle_rounded,
                                      theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Версия на этом устройстве:',
                                      _deviceVersion.isNotEmpty
                                          ? _deviceVersion
                                          : 'Загрузка...',
                                      theme,
                                      Icons.phone_android_rounded,
                                      theme.colorScheme.secondary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Поле минимальной версии
                              TextField(
                                controller: _minimumVersionController,
                                decoration: InputDecoration(
                                  labelText:
                                      'Минимальная поддерживаемая версия *',
                                  hintText: '1.0.0',
                                  helperText:
                                      'Формат: major.minor.patch (например: 1.2.3)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.edit_rounded),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Поле сообщения
                              TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  labelText: 'Сообщение для пользователей',
                                  hintText:
                                      'Пожалуйста, обновите приложение до последней версии',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.message_rounded),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 20),

                              // Переключатель принудительного обновления
                              Container(
                                decoration: BoxDecoration(
                                  color: _forceUpdate
                                      ? theme.colorScheme.errorContainer
                                      : theme
                                          .colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _forceUpdate
                                        ? theme.colorScheme.error
                                            .withValues(alpha: 0.3)
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: SwitchListTile(
                                  title: Text(
                                    'Принудительное обновление',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _forceUpdate
                                        ? '✓ Доступ блокирован для старых версий'
                                        : 'Старые версии продолжают работать',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  value: _forceUpdate,
                                  onChanged: (value) {
                                    setState(() {
                                      _forceUpdate = value;
                                    });
                                  },
                                  secondary: Icon(
                                    _forceUpdate
                                        ? Icons.lock_rounded
                                        : Icons.lock_open_rounded,
                                    color: _forceUpdate
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Кнопка сохранения
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _saveVersion,
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text(
                                    'Сохранить изменения',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              // Информация о последнем обновлении
                              if (version.updatedAt != null) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'Последнее обновление: ${_formatDateTime(version.updatedAt!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  /// Создаёт строку с информацией.
  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
