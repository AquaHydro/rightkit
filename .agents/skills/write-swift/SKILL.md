---
name: write-swift
description: Implement, modify, review, or debug Swift, SwiftUI, AppKit, Xcode, Finder Sync, App Intents, XPC, entitlements, and macOS file-operation code in this repository. Use this skill whenever a task changes RightKit's Swift implementation, tests, Xcode targets, build settings, or macOS integration, even when the user only names a product feature.
---

# Write Swift

Build RightKit as a native macOS product. Prefer small, testable changes that preserve the product specification and make platform limits explicit.

## Start With The Contract

Before editing implementation code, read these files in order:

1. `AGENTS.md`
2. `README.md`
3. `CONTEXT.md`
4. `docs/features.md`
5. `DESIGN.md`
6. `docs/technical.md`
7. `docs/verification.md`
8. `docs/roadmap.md`

Treat `docs/features.md` as the behavior contract and `DESIGN.md` as the visual contract. Keep `F-xxx` and `V-xxx` identifiers stable. When behavior changes, update the feature and verification documents in the same change.

Do not inspect, alter, re-sign, or replace `/Applications/RightKit.app`. Do not read or write its user configuration, templates, directories, or settings.

## Respect Target Boundaries

Keep responsibilities narrow:

- `RightKitCore` contains deterministic domain logic: menu matching, names, collision numbering, protected-path rules, template descriptions, request validation, and hash result types. It does not import SwiftUI and does not perform file I/O.
- `RightKitFinder` builds Finder menus from the synchronous selection snapshot and dispatches intents. It does not open user files, hash, transform images, or mutate files from a menu callback.
- `RightKit` owns persistent settings, file mutations, XPC handling, system integration, and all user-facing windows, dialogs, and errors.

Finder Sync only supplies contextual menus inside configured monitored directories. Do not expand the monitored scope to `/`. The Finder toolbar is only a stable route to Settings and must not infer the current Finder folder or selection.

Use the declared development identifiers without inventing replacements:

- direct (website) channel app: `app.rightkit.mac`, Finder extension `app.rightkit.mac.finder`, App Group `Q9C87Z9H4G.app.rightkit.mac`
- App Store channel app: `app.rightkit.mac.store`, Finder extension `app.rightkit.mac.store.finder`, App Group `Q9C87Z9H4G.app.rightkit.mac.store`
- XPC service: the App Group plus `.command`

Both channels build from the same code. Identifiers come from build settings (`RK_APP_ID`, `RK_APP_GROUP`, `RK_URL_SCHEME`) via Info.plist and `ServiceNames`; never hard-code them in Swift. Only `APP_STORE` compile-time branches may differ, and every such difference must be listed in `F-082`.

The extension and host share the App Group and development team. Validate the XPC caller before processing requests. Treat all request data, URLs, and file names as untrusted until validated.

## Implement In Native Swift

- Use SwiftUI and AppKit system components before custom views. Follow `DESIGN.md`; do not recreate system chrome, color systems, menus, or animations.
- Use Foundation URLs, `FileManager`, `UniformTypeIdentifiers`, `ImageIO`, `AppIntents`, `ServiceManagement`, and Finder Sync APIs rather than shell string construction. The only documented command-line integration is fixed-argument `iconutil` for generated icon sets.
- Keep UI work on the main actor. Put long file, image, and hashing work in cancelable background tasks. Return to the main actor only to publish state or present UI.
- Preserve structured concurrency. Do not add detached tasks unless the lifetime is intentionally independent and cancellation, error handling, and actor isolation are explicit.
- Use typed models and errors. Avoid stringly typed state, force unwraps, silent catch blocks, and broad mutable global state.
- Persist settings atomically in the shared container with `schemaVersion`. Keep user-selected directories as bookmarks and validate stale bookmarks before use.
- Use the one shared collision-numbering and failure-summary path for every file-producing or moving command. Never overwrite a user file.

## Test What Matters

Write focused tests before or alongside core logic. Enumerate relevant invalid inputs and failure paths before writing the tests.

- Use `RightKitCoreTests` for menu tables, target classification, protected paths, collision numbering, template names, request validation, and hash vectors.
- Use a new temporary directory for every file-operation test. Permanently delete only files created by that test.
- Use UI or manual Finder verification for Finder menus, extension enablement, settings windows, system services, App Intents, and visual behavior. Record the macOS version, build commit, monitored directories, steps, and callback logs.
- Keep manual validation honest. A passing unit test does not prove Finder behavior or visual fidelity.

When changing documentation, run:

```sh
python3 scripts/check_docs.py
git diff --check
```

When the project build entrypoint exists, run the focused tests first and then `make verify`. Do not claim a build passed before an Xcode project and scheme exist.

## Work In Small Slices

Follow `docs/roadmap.md`. A feature slice should normally include the model or core logic, the target-specific integration, focused tests, required document updates, and verification evidence.

For platform behavior that is unclear or changes across macOS versions, consult official Apple documentation first. If a public API cannot support the requested behavior, document the constraint and choose a scoped product behavior rather than relying on private APIs or undocumented preferences.

## Finish Clearly

Report the changed paths, the behavior covered, commands run, and any manual or real-device validation still needed. Do not report a feature as complete when Finder, signing, entitlement, or visual verification remains untested.
