#!/bin/bash
set -e

# Генерация документации Dart/Flutter
flutter pub global activate dartdoc
flutter pub global run dartdoc --output docs/api

echo "Документация сгенерирована в docs/api/" 