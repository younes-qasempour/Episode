# Known Issues

Verified on **2026-08-12** unless marked otherwise.

## Functional

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Import conflict overrides are global | Low | Similar/ambiguous matches are shown and skipped; preview has strategy/policy selectors but no per-row editor. | Confirm product need, then add explicit per-entry actions without weakening safe defaults. |
| MAL account connection is unavailable | Medium | No registered client, redirect URI, OAuth flow, or secure token store exists. | Obtain product/security configuration before implementing account import. |
| Theme preference is session-only | Low | Root starts at system mode and stores a light/dark selection only in memory. | Confirm persistence/system-mode requirements. |
| Some Profile identity/settings values remain placeholders | Low | Rank, member date, and version are fixed; Notification and About rows remain no-ops. Analytics, customization, account/sync, theme, and data tools are functional. | Confirm product copy and behavior for the remaining fixed/no-op rows. |

## Transfer compatibility and scale

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| MAL release compatibility needs a real-export check | Medium | Official MAL documentation was blocked by site-safety/network policy; fixtures follow the established MAL export structure. | Manually round-trip fresh anime and manga exports before release. |
| XML parsing is bounded but not streaming | Low | 10 MB compressed/25 MB expanded limits apply and `compute` offloads on isolate-capable platforms; `XmlDocument` still builds a DOM. | Add a streaming provider only if measured real libraries exceed current bounds. |
| Web compute is not a worker | Low | Flutter web executes `compute` on the main event loop; a near-limit valid JSON/XML file may pause rendering. | Measure real exports and add a dedicated worker/streaming path if needed. |
| Automatic backups are plaintext and count-retained | Medium | Five full native snapshots live in SharedPreferences. | Decide encryption/storage lifecycle before sensitive account data is introduced. |
| CSV is export-only | Low | No CSV `ImportProvider` exists. | Add only with a documented column/version contract and preview validation. |
| iOS/macOS/Linux file adapters are absent | Medium for those targets | Runner projects are not present; stub adapter reports unsupported. | Add platform runners and native file UX only when those targets enter scope. |

## UI/UX and accessibility

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Intended fonts are not bundled | Medium | Theme references font names absent from `pubspec.yaml`. | Confirm assets/licensing or use supported platform typography. |
| No explicit accessibility validation | Unknown | No contrast, text-scale, keyboard-focus, or screen-reader audit exists. | Define target standard and add focused checks, including transfer screens. |
| Windows file dialogs need interactive release smoke testing | Low | The native adapter compiles and the Windows artifact builds, but automated tests cannot interact with OS modal dialogs. | Pick, import, export, cancel, and overwrite files once on the release machine. |
| WebAssembly output is not currently supported | Low | The JavaScript web release builds, but Flutter's Wasm dry run flags `flutter_secure_storage_web` for `dart:html`/`dart:js_util`. | Upgrade the secure-storage dependency when its web implementation supports Wasm, then add a Wasm build gate. |

## Architecture and data

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Unused persistence dependencies | Low | Hive, Hive Flutter, and path provider remain declared but unused. | Remove through normal package resolution or document one migration plan. |
| No API pagination/cancellation/cache | Medium | Requests use fixed limits; stale responses are discarded but the underlying requests continue, and results are not cached. | Confirm provider constraints and desired pagination/cache behavior. |

## Build and tooling

| Issue | Severity | Evidence / reproduction | Suggested next investigation |
| --- | --- | --- | --- |
| Android production identity/signing is unresolved | High | Episode label, launcher icons, and splash branding are installed, but `com.example.episode` is still a template application ID and release signing is not owner-configured. | Obtain the production application ID and signing process, then verify a release build without committing secrets. |
| Flutter plugins still apply the Kotlin Gradle Plugin | Medium/future | Android debug build succeeds but warns that `device_info_plus` and `package_info_plus` must migrate to Built-in Kotlin for future Flutter versions. | Upgrade to compatible plugin releases when dependency constraints allow. |

## Security

No committed secrets were found. The local library, safety backups, and
exported files are unencrypted and may include notes/tags. Checksums detect
accidental corruption but are not signatures or encryption.

## Resolved on 2026-08-12

- Episode launcher, adaptive/round icon, splash, web PWA/favicon/loading, and
  Windows icon branding are integrated. This does not resolve the separate
  production Android application ID and signing work listed above.
- The active library is a schema-v2 envelope under `episode_media_items`;
  `otaku_log_media_items` remains only as a one-time migration fallback.
- New automatic and pre-sync safety snapshots use the restorable native Episode
  codec; retained snapshots from the former local-envelope shape are converted
  when downloaded.

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
- Native backup, MAL transfer, CSV export, recovery history, and
  Android/web/Windows file adapters are implemented with focused coverage.
- The stale `MyApp` smoke test was replaced with an application-shell test.
- Online/offline package resolution, analyzer, all tests, and the web release
  build pass.

## Resolved on 2026-07-25

- Fabricated provider totals and automatic completion were removed.
- Unknown totals, manual media, explicit release status, and seasonal progress
  were introduced with backward-compatible model decoding.
