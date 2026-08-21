#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> flutter analyze"
flutter analyze --no-fatal-infos --no-fatal-warnings --no-fatal-infos --no-fatal-warnings

echo "==> flutter test (app)"
flutter test

echo "==> flutter test packages/colony_design_system"
flutter test packages/colony_design_system

echo "==> flutter test packages/colony_domain"
flutter test packages/colony_domain

echo "==> flutter test packages/colony_database"
flutter test packages/colony_database

echo "==> test:all passed"
