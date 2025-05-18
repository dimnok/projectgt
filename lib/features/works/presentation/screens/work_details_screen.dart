import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work.dart';
import '../providers/work_provider.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/notifications_service.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'work_details_panel.dart';
import 'dart:developer' as developer;

/// Экран деталей смены с вкладками работ, материалов и часов.
///
/// Используется для отображения детальной информации о смене,
/// а также для управления списками работ, материалов и часов.
class WorkDetailsScreen extends ConsumerWidget {
  /// Идентификатор смены для отображения деталей.
  final String workId;
  
  /// Создаёт экран деталей смены по [workId].
  const WorkDetailsScreen({super.key, required this.workId});

  /// Получает профиль пользователя по [userId] через репозиторий.
  /// Возвращает [Profile] или null в случае ошибки.
  Future<Profile?> _getUserProfile(String userId, WidgetRef ref) async {
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile(userId);
      return profile;
    } catch (e) {
      developer.log('Error fetching profile for user $userId: $e', name: 'work_details_screen');
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workAsync = ref.watch(workProvider(workId));
    final isMobile = ResponsiveUtils.isDesktop(context) == false;
    final theme = Theme.of(context);
    
    if (workAsync == null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Смена',
          leading: isMobile ? const BackButton() : null,
        ),
        body: const Center(child: Text('Смена не найдена')),
      );
    }
    
    // Получаем информацию об объекте
    final objects = ref.watch(objectProvider).objects;
    final object = objects.where((o) => o.id == workAsync.objectId).isNotEmpty
        ? objects.firstWhere((o) => o.id == workAsync.objectId)
        : null;
    final objectDisplay = object != null ? object.name : workAsync.objectId;
    
    // Получаем информацию о статусе
    final (statusText, statusColor) = _getWorkStatusInfo(workAsync.status);
    
    return Scaffold(
      appBar: AppBarWidget(
        title: isMobile ? 'Смена' : 'Смена: ${_formatDate(workAsync.date)}',
        leading: isMobile ? const BackButton() : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.amber),
            onPressed: () => _showEditWorkDialog(context, ref, workAsync),
            tooltip: 'Редактировать',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDeleteWork(context, ref, workAsync),
            tooltip: 'Удалить',
          ),
        ],
        showThemeSwitch: !isMobile,
        centerTitle: isMobile,
      ),
      drawer: isMobile ? null : const AppDrawer(activeRoute: AppRoute.works),
      body: Builder(
        builder: (scaffoldContext) => isMobile 
          ? SafeArea(
              top: false,
              child: Column(
                children: [
                  FutureBuilder<Profile?>(
                    future: _getUserProfile(workAsync.openedBy, ref),
                    builder: (context, snapshot) {
                      final String openedBy = snapshot.hasData && snapshot.data?.shortName != null
                          ? snapshot.data!.shortName!
                          : 'ID: ${workAsync.openedBy.length > 4 ? "${workAsync.openedBy.substring(0, 4)}..." : workAsync.openedBy}';
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(_formatDate(workAsync.date), style: theme.textTheme.titleLarge),
                                  const SizedBox(width: 16),
                                  AppBadge(
                                    text: statusText,
                                    color: statusColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _infoRow('Объект:', objectDisplay),
                              _infoRow('Открыл:', openedBy),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                  Expanded(
                    child: WorkDetailsPanel(workId: workId, parentContext: scaffoldContext),
                  ),
                ],
              ),
            )
          : WorkDetailsPanel(workId: workId, parentContext: scaffoldContext),
      ),
    );
  }
  
  /// Форматирует дату [date] в строку "дд.мм.гггг".
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  /// Строит строку с подписью и значением для карточки информации.
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  /// Возвращает текст и цвет для статуса смены.
  (String, Color) _getWorkStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', Colors.green);
      case 'closed':
        return ('Закрыта', Colors.red);
      default:
        return (status, Colors.blue);
    }
  }
  
  /// Показывает диалог редактирования статуса смены.
  void _showEditWorkDialog(BuildContext context, WidgetRef ref, Work? work) {
    if (work == null) return;
    final statusController = TextEditingController(text: work.status);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать смену'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: statusController,
              decoration: const InputDecoration(
                labelText: 'Статус',
                hintText: 'Введите статус (open/closed)',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (statusController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите статус смены')),
                );
                return;
              }
              final updatedWork = Work(
                id: work.id,
                date: work.date,
                objectId: work.objectId,
                openedBy: work.openedBy,
                status: statusController.text.trim(),
                photoUrl: work.photoUrl,
                eveningPhotoUrl: work.eveningPhotoUrl,
                createdAt: work.createdAt,
                updatedAt: DateTime.now(),
              );
              await ref.read(worksProvider.notifier).updateWork(updatedWork);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Смена обновлена')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
  
  /// Показывает диалог подтверждения удаления смены.
  void _confirmDeleteWork(BuildContext context, WidgetRef ref, Work work) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы действительно хотите удалить смену от ${_formatDate(work.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (work.id == null) return;
              
              await ref.read(worksProvider.notifier).deleteWork(work.id!);
              if (context.mounted) {
                Navigator.of(context).pop();
                context.goNamed('works');
                NotificationsService.showErrorNotification(context, 'Смена удалена');
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
} 