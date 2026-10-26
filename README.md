# TaskLearn

A small **learning project**: a task list in SwiftUI with Swift Concurrency and GRDB (SQLite).
It is not production experience. I built it to practise the pieces a real iOS codebase uses.

## What it shows
- `TaskCore` (Swift package): model, SQLite storage with GRDB, versioned migrations, async API, live observation.
- Tests with Swift Testing, including one that checks existing user data survives a new migration.
- SwiftUI screen with an `@Observable`, `@MainActor` view model and `.task` for observation.
- Accessibility labels and values on rows.

## Run the tests
```bash
cd TaskCore
swift test
```

## Run the app
1. Xcode: File > New > Project > iOS App, name it `TaskLearn` (SwiftUI, Swift).
2. File > Add Package Dependencies > Add Local... > choose the `TaskCore` folder.
3. Delete the generated `ContentView` and app file, drag the three files from `App/` into the project.
4. Run on a simulator.

## Status
Written without a Swift toolchain at hand: **first build may need small fixes**. See `LEARNING.md`.
