#!/usr/bin/env bash

set -euo pipefail

# Run from the root of your Flutter project

DIRECTORIES=(
  "lib/core/shared_kernel"
  "lib/core/ids"
  "lib/core/results"
  "lib/core/exceptions"
)

FILES=(
  "lib/core/shared_kernel/entity.dart"
  "lib/core/shared_kernel/aggregate_root.dart"
  "lib/core/shared_kernel/value_object.dart"
  "lib/core/shared_kernel/domain_event.dart"
  "lib/core/shared_kernel/domain_exception.dart"
  "lib/core/shared_kernel/guard.dart"
  "lib/core/shared_kernel/specification.dart"
  "lib/core/shared_kernel/clock.dart"

  "lib/core/ids/strongly_typed_id.dart"
  "lib/core/ids/event_id.dart"
  "lib/core/ids/user_id.dart"
  "lib/core/ids/life_journey_id.dart"
  "lib/core/ids/journey_id.dart"
  "lib/core/ids/quest_id.dart"
  "lib/core/ids/mission_id.dart"
  "lib/core/ids/reflection_id.dart"
  "lib/core/ids/contribution_id.dart"
  "lib/core/ids/discovery_profile_id.dart"
  "lib/core/ids/influence_id.dart"
  "lib/core/ids/narrative_theme_id.dart"

  "lib/core/results/result.dart"
  "lib/core/results/success.dart"
  "lib/core/results/failure.dart"

  "lib/core/exceptions/validation_exception.dart"
  "lib/core/exceptions/invariant_violation_exception.dart"
  "lib/core/exceptions/not_found_exception.dart"
  "lib/core/exceptions/concurrency_exception.dart"
)

echo "Creating directories..."
for dir in "${DIRECTORIES[@]}"; do
  mkdir -p "$dir"
done

echo "Creating files..."
for file in "${FILES[@]}"; do
  touch "$file"
done

echo
echo "Created ${#DIRECTORIES[@]} directories"
echo "Created ${#FILES[@]} files"
echo "Shared Kernel structure initialized successfully."