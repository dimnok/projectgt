import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

/// Экран с инструкциями по работе с приложением.
///
/// Содержит подробные руководства по каждому модулю системы в стиле Apple Settings:
/// - Как правильно заполнять данные
/// - Пошаговые инструкции для каждого раздела
/// - Примеры корректного использования функций
/// - Часто задаваемые вопросы (FAQ)
class InstructionsScreen extends StatelessWidget {
  /// Создаёт экран инструкций.
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF1C1C1E),
      appBar: const AppBarWidget(
        title: 'Инструкции',
        leading: BackButton(),
      ),
      body: ContentConstrainedBox(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: Text(
                  'РУКОВОДСТВА ПО МОДУЛЯМ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Группа инструкций
              AppleMenuGroup(
                children: [
                  AppleMenuItem(
                    icon: CupertinoIcons.cube_box,
                    iconColor: const Color(0xFF007AFF),
                    title: 'Материалы',
                    subtitle: 'Импорт накладных, привязка к смете',
                    onTap: () => _openMaterialsGuide(context),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.doc_text,
                    iconColor: const Color(0xFF34C759),
                    title: 'Табель',
                    subtitle: 'Заполнение табеля рабочего времени',
                    onTap: () => _openTimesheetGuide(context),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.hammer,
                    iconColor: const Color(0xFFFF9500),
                    title: 'Работы',
                    subtitle: 'Создание и отслеживание работ',
                    onTap: () => _openWorksGuide(context),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.list_bullet,
                    iconColor: const Color(0xFFFF3B30),
                    title: 'Сметы',
                    subtitle: 'Создание и управление сметами',
                    onTap: () => _openEstimatesGuide(context),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.person_2,
                    iconColor: const Color(0xFFAF52DE),
                    title: 'Контрагенты',
                    subtitle: 'Управление подрядчиками и поставщиками',
                    onTap: () => _openContractorsGuide(context),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.money_dollar,
                    iconColor: const Color(0xFF5AC8FA),
                    title: 'ФОТ',
                    subtitle: 'Расчёт зарплаты и вычетов',
                    onTap: () => _openFotGuide(context),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Информационная секция
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: Text(
                  'ИНФОРМАЦИЯ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              AppleMenuGroup(
                children: [
                  AppleMenuItem(
                    icon: CupertinoIcons.question_circle,
                    iconColor: theme.colorScheme.primary,
                    title: 'О приложении',
                    subtitle: 'Версия и информация о разработке',
                    onTap: () => _openAboutGuide(context),
                  ),
                  AppleMenuItem(
                    icon: CupertinoIcons.headphones,
                    iconColor: const Color(0xFF5AC8FA),
                    title: 'Служба поддержки',
                    subtitle: 'Контакты и способы связи',
                    onTap: () => _openSupportGuide(context),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Совет
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
                            CupertinoIcons.lightbulb,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Совет',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Обновляйте инструкции и поделитесь опытом с коллегами. Если у вас есть вопросы, обратитесь к администратору.',
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
      ),
    );
  }

  void _openMaterialsGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'Материалы',
      content: _getMaterialsGuideContent(),
    );
  }

  void _openTimesheetGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'Табель',
      content: 'Руководство в разработке',
    );
  }

  void _openWorksGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'Работы',
      content: 'Руководство в разработке',
    );
  }

  void _openEstimatesGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'Сметы',
      content: 'Руководство в разработке',
    );
  }

  void _openContractorsGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'Контрагенты',
      content: 'Руководство в разработке',
    );
  }

  void _openFotGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'ФОТ',
      content: 'Руководство в разработке',
    );
  }

  void _openAboutGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'О приложении',
      content: 'Информация о приложении',
    );
  }

  void _openSupportGuide(BuildContext context) {
    _showInstructionBottomSheet(
      context: context,
      title: 'Служба поддержки',
      content: 'Контакты поддержки',
    );
  }

  /// Показывает инструкцию в bottom sheet в стиле окна редактирования профиля
  void _showInstructionBottomSheet({
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
      return Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
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
        backgroundColor: theme.colorScheme.surface,
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

  String _getMaterialsGuideContent() {
    return '''
📌 МОДУЛЬ МАТЕРИАЛЫ

Система учёта строительных материалов от поставки до использования на объекте.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 ОСНОВНЫЕ ЗАДАЧИ:

1️⃣ ИМПОРТ НАКЛАДНЫХ (Excel файлы)

📍 Где: Откройте "Материалы по М-15" → нажмите ⬆️ (верхняя панель)

✓ Поддерживаемые форматы: .xlsx (рекомендуется), .xls
✓ Можно выбрать один или несколько файлов одновременно
⚠️ НЕ загружайте более 25 файлов за раз!

Процесс:
  1. Нажмите ⬆️ "Импорт" в верхней панели
  2. Выберите 1-25 файлов Excel
  3. Откроется "Предпросмотр импорта" с информацией:
     • 📄 Имя файла
     • 📋 Номер накладной (№12345)
     • 📅 Дата накладной (15.10.2025)
     • 📊 Количество позиций

🔵 Проверка дублей:
  • Если накладная уже загружена: "Уже импортирована 🔵"
  • Система определяет дубль по НОМЕРУ + ДАТЕ
  • Дубли НЕ переимпортируются — защита от ошибок!

✅ Загрузка в БД:
  • Нажмите "Импортировать в БД"
  • Во время загрузки кнопка неактивна

📊 Результат (сообщение после загрузки):
  "Импортировано строк: 45. Импортировано накладных: 3. Пропущено накладных: 2"
  • Строк = позиции материалов в БД
  • Накладных = новые документы
  • Пропущено = дубли

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2️⃣ ПРИВЯЗКА МАТЕРИАЛОВ К СМЕТЕ

📍 Где: "Материалы по М-15" → нажмите ⚙️ (верхняя панель)

✓ Отдельный экран для сопоставления материалов
✓ Система автоматически проверяет существующие привязки

Процесс:
  1. Откройте ⚙️ "Сопоставление материалов"
  2. Выберите договор (если нужен конкретный)
  3. Введите поисковый запрос для материала
  4. Система покажет похожие позиции со ОЦЕНКОЙ похожести
  5. Выберите нужную позицию

🔄 Коэффициент конверсии (если единицы разные):
  • Пример 1: накладная в шт, смета в м → 1 шт = 2 м → коэффициент 2.0
  • Пример 2: упак, смета в шт → 1 упак = 100 шт → коэффициент 100.0
  • Валидация: > 0 и ≤ 10000

✅ После привязки:
  • При следующем импорте материал привяжется АВТОМАТИЧЕСКИ!
  • Со временем большинство материалов определятся сами

💡 Совет: Начните с часто используемых материалов

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3️⃣ ПРОСМОТР ТАБЛИЦЫ МАТЕРИАЛОВ

📍 Главный экран "Материалы по М-15"

Колонки таблицы:
  • Наименование — название из накладной
  • Ед. изм. — единица (шт, м, м3, л, кг)
  • Остаток — осталось материала
  • Использовано — расходовано на объекте
  • Накладная — номер документа
  • Дата — дата поступления

Фильтры в верхней панели:
  🔍 Поиск — найти материал по названию
  📅 Дата — выбрать период
  📋 Договоры — выбрать один или несколько
  ⬆️ Импорт — загрузить файлы
  ⚙️ Сопоставление — привязать материалы
  ⬇️ Экспорт — выгрузить в Excel

Пример: Проверить материалы по "Договор №244" за октябрь:
  1. Нажмите договор в чипсах ✓
  2. Нажмите 📅, выберите даты
  3. Таблица обновится автоматически!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4️⃣ ПРОВЕРКА РАСХОДА МАТЕРИАЛОВ

Формула: Остаток = Количество - Использовано

Пример нормального состояния:
  ✓ Кирпич: поступило 10000, использовано 7500, остаток 2500 ✓
  ✓ Цемент: поступило 500, использовано 250, остаток 250 ✓

Если остаток НЕПРАВИЛЬНЫЙ:
  ❌ Отрицательный остаток → ошибка при привязке (коэффициент)
  ❌ Слишком большой остаток → проверить привязку

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5️⃣ ЭКСПОРТ ОТЧЁТА

📍 Где: Нажмите ⬇️ в верхней панели

✓ Установите фильтры (договор, даты, поиск)
✓ Будут экспортированы ТОЛЬКО видимые материалы
✓ Файл: Материал_по_М-15_04_2025-10-15.xlsx

Использование:
  • Аналитика и проверка остатков
  • Печать отчётов
  • Отправка руководителю
  • Передача в бухгалтерию

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ ЧАСТЫЕ ОШИБКИ:

❌ "Накладная определяется как дубль"
  → НОРМАЛЬНО! Система защищена от дублирования
  → Вы видите: "Уже импортирована 🔵"
  → Не загружайте снова — она в БД

❌ "Остаток отрицательный"
  → Проверьте коэффициент конверсии при привязке
  → Может быть ошибка в расчёте (0.5 вместо 2.0)

❌ "Материал не загружается"
  → Используйте Excel (.xlsx или .xls), не CSV
  → CSV НЕ поддерживается!
  → Макс. 25 файлов за раз

❌ "Файл .xls парсится с ошибками"
  → Попросите .xlsx вместо .xls
  → .xlsx более надёжный

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 СОВЕТЫ:

• Загружайте накладные СРАЗУ после получения
• Если 25+ файлов → разделите на несколько загрузок
• Начните привязку с часто используемых материалов
• Сортируйте по "Остаток" чтобы найти заканчивающиеся
• Экспортируйте отчёты в конце недели
• При проблемах обратитесь к руководителю
    ''';
  }
}
