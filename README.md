# Personal Task Manager

A small but production-quality **Flutter** task-manager app built for the Krystal
Digital Solutions technical assessment. It demonstrates clean, layered
architecture, idiomatic **Riverpod** state management, and local persistence
with **Hive**, backed by a full test suite across every layer.

---

## Links

| | |
|---|---|
| **GitHub repository** | `<add your public repo URL here>` |
| **APK (Google Drive)** | `<add your public Drive link here>` |

> The compiled release APK is produced at
> `build/app/outputs/flutter-apk/app-release.apk` (universal, ~47 MB). Upload
> that file to Google Drive, set sharing to **Anyone with the link**, and paste
> the link above.

---

## Features

All the features from the brief are implemented:

- **Task list** with title, description and completion status.
- **Empty state** — a distinct, friendly message when there are no tasks (and a
  separate one when a search returns no matches).
- **Add / edit tasks** — a single form screen handles both, with input
  validation (title required, length limits) and a saving indicator.
- **Toggle completion** — tap the checkbox; completed tasks are struck through
  and sorted to the bottom.
- **Delete with confirmation** — swipe a task left to delete; a confirmation
  dialog guards the action, and an **Undo** snackbar lets you restore it.
- **Search** — filter by title *or* description, case-insensitively, live as
  you type.
- **Data persistence** — tasks survive app restarts via Hive local storage.
- **Loading & error states** — the list shows a spinner while loading and a
  retryable error view if storage fails.
- **Light & dark themes** — Material 3, driven by a single seed colour and the
  system theme.
- **Pull to refresh** on the task list.

---

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.38.5 / Dart 3.10.4 |
| State management | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) 3.x (manual providers, no code-gen) |
| Local storage | [`hive_ce`](https://pub.dev/packages/hive_ce) + `hive_ce_flutter` (Hive Community Edition) |
| Value equality | [`equatable`](https://pub.dev/packages/equatable) |
| Testing | `flutter_test` + [`mocktail`](https://pub.dev/packages/mocktail) |
| Lints | `flutter_lints` + stricter analyzer options |

Exact resolved versions are pinned in [`pubspec.lock`](pubspec.lock).

---

## Architecture

The app uses a **layer-first clean architecture** with three layers plus a small
shared `core`. Because the app is essentially one feature (tasks), a
layer-first layout is clearer than feature-first folders, which would just
create empty ceremony at this scale.

```
lib/
├── main.dart                         App entry: init Hive, open box, runApp
├── app.dart                          MaterialApp (theme + home)
│
├── core/                             Cross-cutting, framework-light helpers
│   ├── constants/app_constants.dart
│   ├── error/task_exception.dart     Single domain-level error type
│   ├── theme/app_theme.dart          Material 3 light/dark themes
│   └── utils/date_formatter.dart
│
├── domain/                           Business contracts — no Flutter, no Hive
│   ├── entities/task.dart            Pure, immutable entity (Equatable)
│   └── repositories/task_repository.dart   Abstract interface (the test seam)
│
├── data/                             Storage implementation
│   ├── models/task_model.dart        Hive model + hand-written TypeAdapter + mapper
│   ├── datasources/task_local_data_source.dart   Thin wrapper over the Hive Box
│   └── repositories/task_repository_impl.dart     Maps model<->entity, wraps errors
│
└── presentation/                     UI + state
    ├── providers/task_providers.dart Riverpod wiring + notifiers (the "view models")
    ├── screens/                      task_list_screen.dart, task_form_screen.dart
    └── widgets/                      task_tile, search field, empty state, error view, dialog
```

**Dependency direction** points inward — `presentation` and `data` depend on
`domain`, never the reverse:

```
Widget → Riverpod notifier → TaskRepository (abstract)
                                   ▲
                                   │ implements
                          TaskRepositoryImpl → TaskLocalDataSource → Hive Box

(entities cross the boundary; Hive TaskModels never leave the data layer)
```

### Why the entity/model split?

`Task` (domain) is a pure, immutable Dart object with value equality. `TaskModel`
(data) carries the Hive concerns — `typeId`, field indices, the binary adapter —
and maps to/from `Task`. Keeping them separate means storage details never leak
into business logic or the UI, and the storage format can evolve independently.

### Deliberately *not* included

To keep the code senior rather than over-engineered (Flutter's own
[architecture guide](https://docs.flutter.dev/app-architecture/guide) calls the
domain use-case layer optional), the following were intentionally skipped for an
app this size:

- **Use-case classes** — for straight CRUD they would just forward to the
  repository. Orchestration lives in the notifier instead.
- **`dartz`/`fpdart` `Either`** — errors are surfaced through Riverpod's
  `AsyncValue.error`; a single `TaskException` is enough.
- **`get_it`/`injectable`** — Riverpod already provides dependency injection via
  provider overrides.

These would be reasonable additions as the app grows; noting the trade-off is
part of the point.

---

## State management approach

State management uses **Riverpod 3 with hand-written providers** (no
`build_runner` / code generation). Code generation is Riverpod's officially
recommended default, but for a small, reviewer-facing project the manual API is
the more robust choice: the repo **compiles the instant it is cloned** — no
generation step, no committed `*.g.dart` files that can drift — and every
provider is readable in one place.

The task list is an **`AsyncNotifier<List<Task>>`** — effectively the view
model. It gives loading / data / error states for free through `AsyncValue`,
which the UI renders with a single `.when(...)`.

Every mutation follows the idiomatic **mutate-then-reload** pattern:

```dart
Future<void> deleteTask(String id) async {
  state = await AsyncValue.guard(() async {
    await _repository.deleteTask(id);
    return _repository.getTasks(); // reload -> a brand-new list instance
  });
}
```

`AsyncValue.guard` captures any thrown error into an `AsyncError` state (no
manual try/catch), and reloading from the repository always yields a *new* list
instance so listeners are correctly notified.

Providers used:

- `taskListProvider` — `AsyncNotifierProvider`, the source of truth for tasks.
- `searchQueryProvider` — a tiny `NotifierProvider<String>` holding the query.
- `filteredTasksProvider` — a derived `Provider` that watches both and returns
  the filtered + sorted list. Filtering/sorting lives here, not in a widget's
  `build`, so it's declarative and independently testable.
- `taskRepositoryProvider` / `taskLocalDataSourceProvider` / `taskBoxProvider` —
  the composition root. The Hive box is opened once in `main()` and injected via
  an override, which keeps async box-opening out of the widget tree and makes
  the whole graph trivial to override with fakes in tests.

---

## Persistence

Persistence uses **Hive Community Edition (`hive_ce`)** rather than the original
`hive` package, which is effectively unmaintained. The `TypeAdapter` is
**hand-written** (rather than generated) to keep the no-build-step story
consistent — its binary format matches exactly what the generator would emit.

Tasks are stored in a typed `Box<TaskModel>` keyed by task id, so updates and
deletes are addressable and search is a simple in-memory filter over
`box.values`.

---

## Getting started

Prerequisites: Flutter 3.38+ (Dart 3.10+).

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app (device or emulator)
flutter run

# 3. Run the analyzer and the test suite
flutter analyze
flutter test

# 4. Build a release APK (universal / fat APK, installable on any device)
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

---

## Testing

26 tests cover every layer:

| Layer | File | What it verifies |
|---|---|---|
| Domain | `test/domain/entities/task_test.dart` | Value equality, `copyWith` immutability |
| Data | `test/data/models/task_model_test.dart` | Lossless entity<->model mapping |
| Data | `test/data/datasources/task_local_data_source_test.dart` | Real Hive round-trip (exercises the hand-written adapter) |
| Data | `test/data/repositories/task_repository_impl_test.dart` | Mapping, delegation and error-wrapping (mocktail) |
| Presentation | `test/presentation/providers/task_list_notifier_test.dart` | Add / edit / toggle / delete / undo / error state |
| Presentation | `test/presentation/providers/filtered_tasks_test.dart` | Search matching + sort order |
| Presentation | `test/presentation/screens/task_list_screen_test.dart` | Empty states, rendering, live search, swipe-to-delete confirmation + undo |

Tests run entirely on an in-memory fake repository or a temp-directory Hive box,
so they are fast and touch no real device storage.

---

## Challenges & notes

- **Riverpod 3 auto-retry.** Riverpod 3 automatically retries a provider whose
  `build` throws. That's good UX in the app, but it made the error-path unit test
  flaky (background rebuilds against a disposed container). The test container
  disables retry (`retry: (_, _) => null`) for determinism; the app keeps it.
- **Hive edition.** The original `hive`/`hive_flutter` packages are abandoned;
  switching to the community `hive_ce` fork was necessary for Dart 3.10.
- **Distribution APK.** A **universal** APK is built (not `--split-per-abi`) so a
  single file installs on any reviewer device. It is signed with the debug key —
  standard and fine for a sideloaded assessment build (a real store release would
  use an upload keystore).

## Assumptions

- Single-user, single-device app — no accounts, sync or backend.
- Task ids are generated from `DateTime.now().microsecondsSinceEpoch`, which is
  unique enough for one user creating tasks by hand.
- Description is optional; title is required.
- "Persistence between sessions" means local device storage (Hive), which is the
  storage named in the brief.

---

## Estimated time spent

Approximately **7–8 hours**, including project setup, architecture, UI,
persistence, the test suite, and this documentation.
