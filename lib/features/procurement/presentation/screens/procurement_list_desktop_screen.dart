import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/procurement/domain/entities/procurement_application.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/procurement/presentation/widgets/procurement_settings_panel.dart';

/// Экран списка заявок на закупку для Desktop версии.
///
/// Отображает:
/// - Список заявок в левой панели.
/// - Детальную информацию о выбранной заявке или панель настроек в правой части.
class ProcurementListDesktopScreen extends ConsumerStatefulWidget {
  /// Список заявок для отображения.
  final List<ProcurementApplication> applications;

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Флаг видимости панели настроек.
  final bool isSettingsVisible;

  /// Создаёт экран списка заявок (Desktop).
  const ProcurementListDesktopScreen({
    super.key,
    required this.applications,
    required this.isLoading,
    this.isSettingsVisible = false,
  });

  @override
  ConsumerState<ProcurementListDesktopScreen> createState() =>
      _ProcurementListDesktopScreenState();
}

class _ProcurementListDesktopScreenState
    extends ConsumerState<ProcurementListDesktopScreen> {
  ProcurementApplication? _selectedApplication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(38, 40, 42, 1)
              : const Color.fromRGBO(248, 249, 250, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Левая панель - список заявок
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 350,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: widget.isLoading && widget.applications.isEmpty
                            ? const Center(child: CupertinoActivityIndicator())
                            : widget.applications.isEmpty
                                ? const Center(child: Text('Заявки не найдены'))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: widget.applications.length,
                                      itemBuilder: (context, index) {
                                        final application =
                                            widget.applications[index];
                                        final isSelected =
                                            _selectedApplication?.id ==
                                                application.id;
                                        return _ApplicationListTileDesktop(
                                          application: application,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedApplication =
                                                  application;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !widget.isSettingsVisible,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: widget.isSettingsVisible ? 1.0 : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Правая панель - детали или настройки
              Expanded(
                child: Stack(
                  children: [
                    // Панель деталей (выезжает вниз)
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      offset: widget.isSettingsVisible
                          ? const Offset(0, 1.2) // Уезжает вниз
                          : Offset.zero,
                      child: _buildDetailPanel(theme),
                    ),

                    // Панель настроек (выезжает сверху)
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      offset: widget.isSettingsVisible
                          ? Offset.zero
                          : const Offset(0, -1.2), // Прячется наверху
                      child: const ProcurementSettingsPanel(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(ThemeData theme) {
    if (_selectedApplication == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Выберите заявку из списка',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final application = _selectedApplication!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка заявки
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.cart,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.readableId ??
                            'Заявка #${application.id.substring(0, 8)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (application.object != null)
                        Text(
                          application.object!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(theme, application.status),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Левая колонка: Инфо и Позиции
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная информация
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              theme,
                              'Дата создания',
                              formatRuDate(application.createdAt),
                            ),
                            const SizedBox(height: 8),
                            if (application.requester != null)
                              _buildInfoRow(
                                theme,
                                'Создал',
                                application.requester!.fullName,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Список позиций
                      Text(
                        'Позиции заявки',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (application.items.isEmpty)
                        Text(
                          'Нет позиций',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        ...application.items.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '$index. ${item.itemName} - ${item.quantity}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Правая колонка: История согласования
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'История',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHistoryItem(
                          theme,
                          status: 'created',
                          date: application.createdAt,
                          actorName: application.requester?.fullName,
                        ),
                        ...application.history.reversed
                            .map((historyItem) => _buildHistoryItem(
                                  theme,
                                  status: historyItem.newStatus,
                                  date: historyItem.changedAt,
                                  actorName: historyItem.actor?.fullName,
                                  comment: historyItem.comment,
                                )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    ThemeData theme, {
    required String status,
    required DateTime date,
    String? actorName,
    String? comment,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(status),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusName(status),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRuDateTime(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (actorName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    actorName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (comment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'created':
        return 'Создана';
      case 'draft':
        return 'Черновик';
      case 'pending_approval':
        return 'На согласовании';
      case 'approved':
        return 'Согласовано';
      case 'invoice_uploaded':
        return 'Счет загружен';
      case 'processing':
        return 'В обработке';
      case 'awaiting_payment':
        return 'Ожидает оплаты';
      case 'paid':
        return 'Оплачено';
      case 'rejected':
        return 'Отклонено';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created':
        return Colors.blue;
      case 'approved':
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending_approval':
      case 'awaiting_payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final color = _getStatusColor(status);
    final text = _getStatusName(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ApplicationListTileDesktop extends StatelessWidget {
  final ProcurementApplication application;
  final bool isSelected;
  final VoidCallback onTap;

  const _ApplicationListTileDesktop({
    required this.application,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors matching RoleListItem style
    final selectedBackgroundColor =
        isDark ? Colors.grey[800] : Colors.grey[200];
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    const selectedTextColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Material(
        color: isSelected ? selectedBackgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: hoverColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.cart,
                  size: 20,
                  color: isSelected
                      ? selectedTextColor
                      : theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.readableId ??
                            'Заявка #${application.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? selectedTextColor
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (application.object != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          application.object!.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? selectedTextColor.withValues(alpha: 0.8)
                                : theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            formatRuDate(application.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? selectedTextColor.withValues(alpha: 0.6)
                                  : theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(application.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending_approval':
      case 'awaiting_payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
