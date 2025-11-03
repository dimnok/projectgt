import 'package:flutter/material.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран управления выданным имуществом (ТМЦ).
///
/// Отображает категории товарно-материальных ценностей в стиле Apple Settings.
/// По нажатию на категорию показывает примеры выданного имущества.
///
/// Пример использования:
/// ```dart
/// PropertyScreen();
/// ```
class PropertyScreen extends StatelessWidget {
  /// Создаёт экран управления ТМЦ.
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7) // iOS светлый grouped background
          : const Color(0xFF1C1C1E), // iOS темный grouped background
      appBar: const AppBarWidget(
        title: 'Выданное имущество (ТМЦ)',
        leading: BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок секции
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                'КАТЕГОРИИ ИМУЩЕСТВА',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Группа элементов имущества
            _AppleMenuGroup(
              children: [
                _AppleMenuItem(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.orange,
                  title: 'Средства индивидуальной защиты (СИЗы)',
                  subtitle:
                      'Каски, перчатки, респираторы, системы безопасности',
                  onTap: () => _showPropertyInfo(
                    context: context,
                    title: 'СИЗы',
                    content: _getSizContent(),
                  ),
                ),
                _AppleMenuItem(
                  icon: Icons.construction_outlined,
                  iconColor: Colors.blue,
                  title: 'Инструменты',
                  subtitle: 'Электроинструменты и ручной инструмент',
                  onTap: () => _showPropertyInfo(
                    context: context,
                    title: 'Инструменты',
                    content: _getToolsContent(),
                  ),
                ),
                _AppleMenuItem(
                  icon: Icons.devices_other_outlined,
                  iconColor: Colors.purple,
                  title: 'Оргтехника',
                  subtitle: 'Компьютеры, планшеты, ноутбуки, телефоны',
                  onTap: () => _showPropertyInfo(
                    context: context,
                    title: 'Оргтехника',
                    content: _getOfficeTechContent(),
                  ),
                ),
                _AppleMenuItem(
                  icon: Icons.checkroom_outlined,
                  iconColor: Colors.green,
                  title: 'Спецодежда и обувь',
                  subtitle: 'Костюмы, рубашки, брюки, сапоги, спецодежда',
                  onTap: () => _showPropertyInfo(
                    context: context,
                    title: 'Спецодежда',
                    content: _getUniformContent(),
                  ),
                ),
                _AppleMenuItem(
                  icon: Icons.inventory_outlined,
                  iconColor: Colors.red,
                  title: 'Прочее имущество',
                  subtitle: 'Ключи, проходные, форменные знаки, материалы',
                  onTap: () => _showPropertyInfo(
                    context: context,
                    title: 'Прочее имущество',
                    content: _getOtherPropertyContent(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Информационная карточка
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Статус разработки',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Модуль управления ТМЦ находится в разработке. Полная функциональность учёта имущества будет доступна в ближайшем обновлении приложения.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Показывает информацию о категории имущества в bottom sheet
  void _showPropertyInfo({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              height: 1,
            ),

            // Содержимое
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSizContent() {
    return '''🛡️ СРЕДСТВА ИНДИВИДУАЛЬНОЙ ЗАЩИТЫ (СИЗы)

⚠️ СТАТУС: Модуль в разработке

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ВЫДАННОЕ ВАМ ИМУЩЕСТВО (пример):

✓ Каска строительная (оранжевая)
  📅 Выдано: 15.10.2025
  ⏳ Статус: В использовании
  📝 Примечание: Габариты объекта
  
✓ Перчатки хлопчатобумажные (упак. 10 шт)
  📅 Выдано: 10.10.2025
  ⏳ Статус: В использовании
  📝 Примечание: Демонтажные работы

✓ Респиратор FFP2
  📅 Выдано: 08.10.2025
  ⏳ Статус: В использовании
  📝 Примечание: Заготовка изоляции

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 СТАТИСТИКА:

• Выдано всего: 3 единицы
• В использовании: 3
• Возвращено: 0
• Потеряно: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️ При полной реализации модуля:

• История выдачи и возврата имущества
• Отслеживание статуса каждого предмета
• Напоминания о возврате
• Загрузка фотографий имущества
• Подтверждение выдачи/возврата
• Уведомления о повреждениях''';
  }

  String _getToolsContent() {
    return '''🔧 ИНСТРУМЕНТЫ

⚠️ СТАТУС: Модуль в разработке

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ВЫДАННОЕ ВАМ ИМУЩЕСТВО (пример):

✓ Дрель электрическая DeWalt DCD720C2
  📅 Выдано: 12.10.2025
  ⏳ Статус: В использовании
  📝 Примечание: Монтаж электроустановочных изделий
  📸 Фото: Загружено
  
✓ Уровень спиртовой 1000 мм
  📅 Выдано: 12.10.2025
  ⏳ Статус: В использовании
  📝 Примечание: Разметка потолков

✓ Болгарка Makita 115 мм
  📅 Выдано: 10.10.2025
  ⏳ Статус: Возвращено
  📅 Возвращено: 15.10.2025
  📝 Состояние: Хорошее

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 СТАТИСТИКА:

• Выдано всего: 3 единицы
• В использовании: 2
• Возвращено: 1
• Повреждено: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️ При полной реализации модуля:

• Каталог инструментов с характеристиками
• Отслеживание технического состояния
• Графики техническое обслуживания
• История поломок и ремонтов
• Оценка износа
• Уведомления о необходимости ТО''';
  }

  String _getOfficeTechContent() {
    return '''💻 ОРГТЕХНИКА

⚠️ СТАТУС: Модуль в разработке

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ВЫДАННОЕ ВАМ ИМУЩЕСТВО (пример):

✓ Ноутбук Lenovo ThinkPad E15 Gen 4
  📅 Выдано: 01.09.2025
  ⏳ Статус: В использовании
  📝 SN: LR15AE2B5678
  📝 Примечание: Служебный ноутбук
  🔐 Статус лицензии: Активна
  
✓ Служебный мобильный телефон iPhone 14
  📅 Выдано: 01.09.2025
  ⏳ Статус: В использовании
  📝 SN: A1B2C3D4E5F6
  📝 Примечание: Связь на объекте
  ☎️ Номер: +7-(XXX)-XXX-XXXX

✓ Планшет Samsung Galaxy Tab S8
  📅 Выдано: 15.08.2025
  ⏳ Статус: Возвращено
  📅 Возвращено: 30.09.2025
  📝 Состояние: Хорошее

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 СТАТИСТИКА:

• Выдано всего: 3 единицы
• В использовании: 2
• Возвращено: 1
• На ремонте: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️ При полной реализации модуля:

• Управление активами и лицензиями
• Отслеживание номеров телефонов
• История использования устройств
• Актуализация ПО и обновления
• Перепись оргтехники
• Интеграция с системой инвентаризации''';
  }

  String _getUniformContent() {
    return '''👔 СПЕЦОДЕЖДА И ОБУВЬ

⚠️ СТАТУС: Модуль в разработке

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ВЫДАННОЕ ВАМ ИМУЩЕСТВО (пример):

✓ Костюм рабочий серый (летний) размер 52
  📅 Выдано: 01.05.2025
  ⏳ Статус: В использовании
  📝 Примечание: Демонтажные работы
  
✓ Сапоги рабочие чёрные размер 42
  📅 Выдано: 01.05.2025
  ⏳ Статус: В использовании
  📝 Примечание: Спецодежда объекта

✓ Жилет сигнальный оранжевый (L)
  📅 Выдано: 15.09.2025
  ⏳ Статус: В использовании
  📝 Примечание: Видимость на дороге

✓ Перчатки хозяйственные (2 пары)
  📅 Выдано: 10.10.2025
  ⏳ Статус: Выдано
  📝 Примечание: Замена, износились

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 СТАТИСТИКА:

• Выдано всего: 4 единицы
• В использовании: 4
• Возвращено: 0
• Износившееся: 1 (требует замены)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️ При полной реализации модуля:

• Подбор размеров и фасонов
• Сроки использования
• График замены износившейся одежды
• История выдачи/возврата
• Требования по чистоте и хранению
• Отчёты по использованию спецодежды''';
  }

  String _getOtherPropertyContent() {
    return '''🔑 ПРОЧЕЕ ИМУЩЕСТВО

⚠️ СТАТУС: Модуль в разработке

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ВЫДАННОЕ ВАМ ИМУЩЕСТВО (пример):

✓ Ключ от кабинета (кв. 305)
  📅 Выдано: 01.10.2025
  ⏳ Статус: В использовании
  📝 Примечание: Рабочий кабинет
  
✓ Пропуск на объект (Ул. Ленина, 25)
  📅 Выдано: 01.10.2025
  ⏳ Статус: Активный
  📝 Примечание: Доступ на все уровни
  ⏳ Действителен до: 31.12.2025

✓ Форменный значок "Бригадир"
  📅 Выдано: 15.09.2025
  ⏳ Статус: В использовании
  📝 Примечание: Форменное отличие

✓ Магнитная карта доступа (чёрная)
  📅 Выдано: 01.10.2025
  ⏳ Статус: Деактивирована
  📅 Возвращено: 10.10.2025
  📝 Причина: Замена на новую (проверка доступа)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 СТАТИСТИКА:

• Выдано всего: 4 единицы
• В использовании: 3
• Возвращено: 1
• Потеряно: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️ При полной реализации модуля:

• Отслеживание ключей и пропусков
• Сроки действия документов
• История деактивации карт
• Напоминания об истечении доступа
• Журнал входа/выхода
• Контроль за потерей критичных предметов''';
  }
}

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

/// Элемент меню в стиле Apple Settings.
///
/// Отображает иконку, заголовок, опциональный подзаголовок и стрелку вправо.
class _AppleMenuItem extends StatelessWidget {
  /// Иконка элемента.
  final IconData icon;

  /// Цвет иконки.
  final Color iconColor;

  /// Основной текст элемента.
  final String title;

  /// Дополнительный текст под заголовком (опционально).
  final String? subtitle;

  /// Коллбэк при нажатии.
  final VoidCallback? onTap;

  /// Создаёт элемент меню в стиле Apple.
  const _AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Иконка в цветном квадратике
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Текст
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
          // Стрелка
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return _IOSTapEffect(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Виджет для создания iOS-подобного эффекта затемнения при нажатии.
///
/// При нажатии элемент затемняется серым фоном, как в iOS Settings.
class _IOSTapEffect extends StatefulWidget {
  /// Дочерний виджет.
  final Widget child;

  /// Коллбэк при нажатии.
  final VoidCallback onTap;

  /// Создаёт виджет с iOS-подобным эффектом нажатия.
  const _IOSTapEffect({
    required this.child,
    required this.onTap,
  });

  @override
  State<_IOSTapEffect> createState() => _IOSTapEffectState();
}

/// Состояние для [_IOSTapEffect].
class _IOSTapEffectState extends State<_IOSTapEffect> {
  /// Флаг нажатия.
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
