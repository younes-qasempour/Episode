# Known Issues

Verified on **2026-08-01** unless marked otherwise.

## Functional

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Real API failures appear as empty results | Medium | Provider methods catch failures/non-200 responses and return `[]`. | Define a typed result/error contract and test network, parse, and rate-limit failures. |
| Older searches can overwrite newer results | Medium | Debounce cancels timers, not active futures. | Add request generations/cancellation and an out-of-order regression test. |
| Import conflict overrides are global | Low | Similar/ambiguous matches are shown and skipped; preview has strategy/policy selectors but no per-row editor. | Confirm product need, then add explicit per-entry actions without weakening safe defaults. |
| MAL account connection is unavailable | Medium | No registered client, redirect URI, OAuth flow, or secure token store exists. | Obtain product/security configuration before implementing account import. |
| Theme preference is session-only | Low | Root starts at system mode and stores a light/dark selection only in memory. | Confirm persistence/system-mode requirements. |
| Profile identity/statistics/notification/About are placeholders | Medium | Fixed strings and no-op rows remain; local data management is the only functional settings destination. | Confirm Profile product scope. |

## Transfer compatibility and scale

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| MAL release compatibility needs a real-export check | Medium | Official MAL documentation was blocked by site-safety/network policy; fixtures follow the established MAL export structure. | Manually round-trip fresh anime and manga exports before release. |
| XML parsing is bounded but not streaming | Low | 10 MB compressed/25 MB expanded limits apply and `compute` offloads on isolate-capable platforms; `XmlDocument` still builds a DOM. | Add a streaming provider only if measured real libraries exceed current bounds. |
| Web compute is not a worker | Low | Flutter web executes `compute` on the main event loop; a near-limit valid JSON/XML file may pause rendering. | Measure real exports and add a dedicated worker/streaming path if needed. |
| Automatic backups are plaintext and count-retained | Medium | Five full native snapshots live in SharedPreferences. | Decide encryption/storage lifecycle before sensitive account data is introduced. |
| CSV is export-only | Low | No CSV `ImportProvider` exists. | Add only with a documented column/version contract and preview validation. |
| iOS/desktop file adapters are absent | Medium for those targets | Runner projects are not present; stub adapter reports unsupported. | Add platform runners and native file UX when those targets enter scope. |

## UI/UX and accessibility

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Intended fonts are not bundled | Medium | Theme references font names absent from `pubspec.yaml`. | Confirm assets/licensing or use supported platform typography. |
| Explore layout is not responsive | Low | Fixed two-column grid and aspect ratio have no breakpoints. | Test phone/tablet/web widths and define breakpoints. |
| No explicit accessibility validation | Unknown | No contrast, text-scale, keyboard-focus, or screen-reader audit exists. | Define target standard and add focused checks, including transfer screens. |

## Architecture and data

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Active library has no envelope schema | Medium | `otaku_log_media_items` remains an additive JSON array; portable backups are separately versioned. | Define a library migration only before an incompatible field change. |
| Unused persistence dependencies | Low | Hive, Hive Flutter, and path provider remain declared but unused. | Remove through normal package resolution or document one migration plan. |
| No API pagination/cancellation/cache | Medium | Requests use fixed limits; stale responses are discarded but the underlying requests continue, and results are not cached. | Confirm provider constraints and desired pagination/cache behavior. |

## Build and tooling

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Android release setup is template-grade | High | Example application ID, debug release signing, and TODOs remain. | Obtain owner identity/signing requirements and verify a release build. |
| Flutter plugins still apply the Kotlin Gradle Plugin | Medium/future | Android debug build succeeds but warns that `device_info_plus` and `package_info_plus` must migrate to Built-in Kotlin for future Flutter versions. | Upgrade to compatible plugin releases when dependency constraints allow. |

## Security

No committed secrets were found. The local library, safety backups, and
exported files are unencrypted and may include notes/tags. Checksums detect
accidental corruption but are not signatures or encryption.

## Resolved on 2026-08-09

- Search now exposes typed failures, retries transport/rate-limit requests with
  a ten-second timeout, protects UI state from stale responses, and applies the
  required provider header and cover URL sanitization.
- Android Gradle resolution succeeded; the debug APK builds successfully.
- The smoke test targets `EpisodeApp`, static analysis is clean, and the full
  154-test suite passes.

## Resolved on 2026-08-01

- Corrupt active library JSON is now surfaced without overwriting the raw
  value; a valid empty library no longer reseeds samples.
- Whole-library import/restore has validated snapshot rollback.
- Native backup, MAL transfer, CSV export, recovery history, and Android/web
  file adapters are implemented with focused coverage.
- The stale `MyApp` smoke test was replaced with an application-shell test.
- Online/offline package resolution, analyzer, all tests, and the web release
  build pass.

## Resolved on 2026-07-25

- Fabricated provider totals and automatic completion were removed.
- Unknown totals, manual media, explicit release status, and seasonal progress
  were introduced with backward-compatible model decoding.
