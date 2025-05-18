import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет адаптивного поля поиска.
///
/// Поддерживает различные размеры экрана и анимацию появления/исчезновения.
class SearchField extends StatelessWidget {
  /// Контроллер текстового поля.
  final TextEditingController controller;
  
  /// Коллбэк при изменении текста.
  final Function(String)? onChanged;
  
  /// Подсказка в поле поиска.
  final String? labelText;
  
  /// Статус видимости поля (только для мобильных устройств).
  final bool isVisible;
  
  /// Высота контейнера поиска.
  static const double _containerHeight = 80.0;
  
  /// Создает адаптивное поле поиска.
  ///
  /// [controller] - контроллер для управления текстом.
  /// [onChanged] - функция обратного вызова при изменении текста.
  /// [labelText] - текст подсказки в поле (по умолчанию "Поиск").
  /// [isVisible] - видимость поля в мобильном режиме.
  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.labelText = 'Поиск',
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    // Десктоп не использует анимацию, мобильный - использует
    return isDesktop 
        ? _buildSearchField(visible: true)
        : _buildAnimatedSearchField(visible: isVisible);
  }
  
  /// Строит анимированное поле поиска для мобильных устройств.
  Widget _buildAnimatedSearchField({required bool visible}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: visible ? _containerHeight : 0,
      child: _buildSearchField(visible: visible),
    );
  }
  
  /// Строит поле поиска.
  Widget _buildSearchField({required bool visible}) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    
    // Определяем, нужна ли кнопка очистки
    final bool showClearButton = controller.text.isNotEmpty;
    final Widget? suffixIcon = showClearButton
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              onChanged?.call('');
            },
          )
        : null;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: suffixIcon,
        ),
        onChanged: onChanged,
      ),
    );
  }
} 