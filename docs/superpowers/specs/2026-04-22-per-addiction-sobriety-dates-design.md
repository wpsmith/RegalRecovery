# Per-Addiction Sobriety Dates in Onboarding

## Problem

The onboarding flow applies a single sobriety date to all selected addictions. Users who started recovery at different times for different addictions cannot set accurate dates during onboarding.

## Solution

Split the current `RecoverySetupView` into two screens and add per-addiction date pickers.

## Screen 1: Addiction Setup (`AddictionSetupView`)

Addiction selection stays as multi-select chips from the predefined list (Sex Addiction, Pornography, Substance Use, Alcohol, Drugs, Gambling, Other).

When a chip is selected, it appears in a "Selected Addictions" list below the chips. Each selected addiction row shows:
- Addiction name
- Sobriety date (defaults to today, displayed as formatted text e.g. "Apr 22, 2026")
- Tapping the row opens the system date picker for that addiction

When a chip is deselected, its row disappears from the list.

The first addiction selected is auto-marked as primary (subtle indicator). User can tap a different row to change primary. This aligns with the API's `isPrimary` flag.

"Continue" button at bottom. Requires at least one addiction selected.

## Screen 2: Motivation Setup (`MotivationSetupView`)

The existing motivation multi-select chips extracted to a dedicated screen. Same UI, same data. "Continue" proceeds to Permissions.

## Data Flow

`RecoverySetupView` splits into `AddictionSetupView` and `MotivationSetupView`. `OnboardingFlow` gains one additional tab step between the current recovery setup position and permissions.

When `completeSetup()` runs, it iterates selected addictions and creates each `RRAddiction` with its individual `sobrietyDate` and `sortOrder`. The first selected addiction gets `isPrimary` (or equivalent sort priority).

## What Doesn't Change

- `RRAddiction` SwiftData model — already supports one sobriety date per addiction
- `RRUser` model — already has `motivations: [String]`
- Permissions screen
- Welcome / Account screens
- OpenAPI spec — already supports multiple addictions with individual dates
