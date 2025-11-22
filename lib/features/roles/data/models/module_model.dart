import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/roles/domain/entities/module.dart';

part 'module_model.freezed.dart';
part 'module_model.g.dart';

/// Модель модуля для работы с API/БД
@freezed
abstract class ModuleModel with _$ModuleModel {
  /// Конструктор для создания [ModuleModel].
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory ModuleModel({
    required String id,
    required String code,
    required String name,
    String? description,
    required String iconKey,
    @Default(0) int sortOrder,
  }) = _ModuleModel;

  const ModuleModel._();

  /// Создаёт [ModuleModel] из JSON.
  factory ModuleModel.fromJson(Map<String, dynamic> json) =>
      _$ModuleModelFromJson(json);

  /// Преобразование в доменную сущность
  Module toEntity() => Module(
        id: id,
        code: code,
        name: name,
        description: description,
        iconKey: iconKey,
        sortOrder: sortOrder,
      );
}
