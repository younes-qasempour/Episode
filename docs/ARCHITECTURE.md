# Architecture

## Summary

OtakuLog uses a lightweight layered structure with Flutter widgets at the top,
repository classes as access boundaries, one HTTP service, one persistence
repository, and one shared model. State is held in `StatefulWidget` objects and
passed through constructor callbacks. There is no separate domain layer,
state-management package, router, or dependency-injection container.

```mermaid
flowchart LR
    App["OtakuLogApp<br/>theme state"] --> Shell["MainNavigationScreen<br/>library state"]
    Shell --> Home["HomeTab"]
    Shell --> Explore["SearchTab"]
    Shell --> Profile["ProfileTab"]
    Shell --> Detail["MediaDetailScreen<br/>Navigator push"]
    Home --> Card["MediaCard"]
    Shell --> LocalRepo["LocalStorageRepository"]
    Explore --> SearchRepo["SearchRepository"]
    SearchRepo --> API["ApiService"]
    API --> Jikan["Jikan REST API"]
    API --> TVMaze["TVMaze REST API"]
    LocalRepo --> Prefs["SharedPreferences<br/>JSON list"]
    LocalRepo --> Seed["sampleMediaItems"]
    API --> Model["MediaItem"]
    LocalRepo --> Model
    Shell --> Model
```

## Presentation and state

### Current approach

- `OtakuLogApp` owns `ThemeMode`.
- `MainNavigationScreen` owns the current tab, loading state, and in-memory
  library list.
- `HomeTab` owns its local filter and search text.
- `SearchTab` owns its query controller, selected category, debounce timer,
  results, loading, and error fields.
- `MediaDetailScreen` owns an editable copy of selected item fields.
- Child-to-parent changes use callbacks.

### Extension pattern

For small changes, keep state with the widget that owns the behavior and pass
dependencies through constructors. When behavior crosses screens, first
extend the existing repository/root callback flow. A state-management package
requires an explicit architectural decision; do not introduce one inside a
single feature.

### Restrictions

- Do not create global mutable state or a parallel service locator.
- Preserve constructor injection seams used by tests:
  `ApiService(http.Client?)`, `SearchRepository(ApiService?)`,
  `SearchTab(SearchRepository?)`, and
  `MainNavigationScreen(LocalStorageRepository?)`.

## Domain and models

`MediaItem` is both the domain-facing UI model and persistence/API mapping
target. It includes identity, title, cover URL, progress, total count, media
type, status, optional synopsis, and rating. It provides progress calculation,
unit labels, `copyWith`, and manual map/JSON conversion.

There is no separate entity/DTO distinction or validation layer. Extend
`MediaItem` only after checking API mapping, stored JSON compatibility, sample
data, cards, detail UI, and tests.

## Data layer

### Remote

`SearchRepository` delegates directly to `ApiService`. `ApiService` builds
public URLs, runs concurrent requests with `Future.wait`, decodes JSON, and
maps provider records into `MediaItem`.

```mermaid
sequenceDiagram
    participant UI as SearchTab
    participant R as SearchRepository
    participant S as ApiService
    participant J as Jikan
    participant T as TVMaze
    UI->>R: searchMedia(query, category)
    R->>S: searchMedia(query, category)
    par selected anime/manga calls
        S->>J: GET top or search endpoint
    and selected series call
        S->>T: GET /search/shows
    end
    S-->>R: combined List<MediaItem>
    R-->>UI: results
```

All service exceptions and non-200 responses become an empty list. There are
no custom error types, authentication, headers, interceptors, retry, timeout,
pagination, or response cache.

### Local

`LocalStorageRepository` stores the entire library as one JSON string under
`otaku_log_media_items`. Empty/missing/invalid data falls back to
`sampleMediaItems` and is saved immediately.

There is no local database schema, migration system, secure storage, or Hive
usage. Do not add a second store beside SharedPreferences. A persistence
replacement needs an explicit migration decision and backward-compatibility
plan.

## Navigation

- Root: `MaterialApp.home`
- Primary navigation: `BottomNavigationBar` + `IndexedStack`
- Detail navigation: imperative `Navigator.push(MaterialPageRoute(...))`
- Named routes/deep links: not implemented

Add a screen by following the existing callback and `MaterialPageRoute`
pattern unless route scale or a task explicitly justifies a router decision.

## Dependency injection

There is no container. Optional constructor parameters provide manual
injection, and defaults construct production dependencies. Preserve this
pattern for testability.

## Error handling

- API errors: swallowed and represented as empty results.
- Persistence decode errors: swallowed and replaced with sample data.
- Image errors: render a type icon fallback.
- Loading: root spinner for local load and Explore spinner for remote search.
- Save/delete errors: not surfaced.

Any error-model change affects service, repositories, screens, and tests and
must be documented as a decision.

## Configuration and environments

Base URLs are static constants in `ApiService`. There are no flavors,
`--dart-define` keys, environment files, or secret-bearing configuration.
Public API URLs are the only remote configuration.

## Theme, localization, and accessibility

`AppTheme` defines two Material 3 `ThemeData` instances and a partial set of
color/radius constants. Theme mode is callback-driven and in memory.

Localization is absent. Text is embedded in widgets. Semantic labels are
mostly inherited from Material controls; no explicit accessibility standard,
text-scale validation, or focus-navigation test is present.

## Serialization and generated code

Serialization is handwritten in `MediaItem`. No code generator, generated Dart
model, ARB output, or build-runner configuration exists. Do not invent code
generation commands or edit Flutter-generated platform files manually.

## Authentication, background work, and notifications

Not implemented. There are no accounts, tokens, background jobs, push
services, notification permissions, or scheduled work. The Profile
notification and cloud-sync rows are placeholder affordances only.
