#!/bin/bash
set -e

echo "=== Pigeon ==="
cd plugins/vpn_plugin
flutter pub get
dart run pigeon --input pigeons/platform_api.dart
cd ../..

echo "=== intl_utils ==="
dart run intl_utils:generate

echo "=== build_runner ==="
dart run build_runner build --delete-conflicting-outputs

echo "=== Done ==="
