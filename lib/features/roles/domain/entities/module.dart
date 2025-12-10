import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'module.freezed.dart';

/// Доменная сущность модуля системы.
@freezed
abstract class Module with _$Module {
  /// Конструктор для создания [Module].
  const factory Module({
    required String id,
    required String code,
    required String name,
    String? description,
    required String iconKey,
    @Default(0) int sortOrder,
  }) = _Module;

  const Module._();

  /// Получить иконку по ключу (временное решение, пока иконки строковые)
  IconData get icon {
    switch (iconKey) {
      case 'person_3':
        return CupertinoIcons.person_3;
      case 'cube_box':
        return CupertinoIcons.cube_box;
      case 'wrench':
        return CupertinoIcons.wrench;
      case 'briefcase':
        return CupertinoIcons.briefcase;
      case 'building_2_fill':
        return CupertinoIcons.building_2_fill;
      case 'creditcard':
        return CupertinoIcons.creditcard;
      case 'time':
        return CupertinoIcons.clock;
      case 'number':
        return CupertinoIcons.list_number;
      case 'briefcase_fill':
        return CupertinoIcons.briefcase_fill;
      case 'doc_text':
        return CupertinoIcons.doc_text;
      case 'export_icon':
        return CupertinoIcons.tray_arrow_down;
      case 'calendar':
        return CupertinoIcons.calendar_today;
      case 'cart':
        return CupertinoIcons.cart;
      case 'person_2':
        return CupertinoIcons.person_2;
      case 'gear_alt':
        return CupertinoIcons.settings;
      case 'lock_shield':
        return CupertinoIcons.lock_shield;
      default:
        return CupertinoIcons.square;
    }
  }
}
