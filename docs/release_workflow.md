# Релиз и публикация (ProjectGT)

Кратко: **«релиз»** — автоматизированный пайплайн; **«запушь обновления»** — только `git push` без сборок.

## Команда «релиз» (полный цикл)

Из **корня** репозитория, с **чистым** `git status` (всё важное закоммичено — релиз сам поднимет версию и сделает новый commit):

```bash
./tools/projectgt_release.sh
```

Что происходит:

1. **Версия** в `pubspec.yaml`: по умолчанию **patch +1** и **build +1** (пример: `1.0.15+40` → `1.0.16+41`). Остальные платформы подхватывают версию из Flutter.
2. `flutter pub get`
3. **Windows**: `flutter build windows --release` и zip артефакта — **только на хосте Windows**; на macOS шаг пропускается (сборку Windows вынести в CI или отдельный ПК).
4. IPA для SideStore (`export-method development`), GitHub Release, обновление `sidestore/source.json` — см. `tools/release_sidestore_ipa.sh`.
5. Если zip Windows собран — загрузка в тот же Release на GitHub.
6. Один **commit**: `pubspec.yaml` + `sidestore/source.json`, затем **push** текущей ветки.

Опции:

- `--skip-bump` — не менять версию в pubspec (повтор при ошибке).
- `--build-only-bump` — только увеличить число после `+`, маркетинговую часть не трогать.

Справка: `./tools/projectgt_release.sh --help`

## «Запушь обновления»

Только отправить **уже созданные** коммиты на GitHub (**без** bump, **без** сборок):

```bash
./tools/push_updates.sh
```

Требуется **чистое** рабочее дерево. Если есть незакоммиченные файлы — сначала commit или stash.

Вручную: `git push origin $(git branch --show-current)` (ожидается, что вы на нужной ветке, например `main`).

## Вспомогательные скрипты

| Файл | Назначение |
|------|------------|
| `tools/bump_pubspec_version.py` | Только bump строки `version:` в pubspec (используется из `projectgt_release.sh`). |
| `tools/release_sidestore_ipa.sh` | Только IPA + SideStore + gh release (можно вызывать отдельно). |

Дата: 2026-05-08.
