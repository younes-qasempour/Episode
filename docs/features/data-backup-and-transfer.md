# Data Backup and Transfer

- **Status:** Functional on Android and web
- **Last verified:** 2026-08-01

## Purpose

Let a user move or protect a local library without an account. The feature
supports OtakuLog-native backups, MyAnimeList XML import/export, readable CSV
export, previewed conflict handling, automatic safety snapshots, and an audit
history.

## User flow

1. Open **Profile & Settings** and choose **Data, Backup & Transfer** (or use
   the settings icon).
2. Pick an OtakuLog JSON backup, MAL XML/XML.GZ export, or a dedicated restore
   action.
3. OtakuLog validates and parses the file before showing any mutation action.
4. Review entry counts, warnings, match reasons, the strategy, and the
   existing-entry policy.
5. Confirm. OtakuLog retains a native safety backup, computes the candidate
   library, writes the complete library, verifies the round trip, and rolls
   back the saved snapshot on failure.
6. Review the result counts and save the safety backup if desired.
7. Open **Transfer history** to inspect the newest 25 operation summaries or
   save one of the five retained safety backups.

Exports use the platform save dialog on Android and a browser download on web.
The Android importer uses the Storage Access Framework; the web importer uses
the browser file input.

## Supported formats

| Format | Import | Export | Notes |
| --- | --- | --- | --- |
| OtakuLog JSON | Yes | Yes | Versioned schema v1, SHA-256 integrity metadata, full current `MediaItem` fields |
| MAL anime XML | Yes | Yes | Plain XML and gzip import; export requires a MAL/Jikan ID |
| MAL manga XML | Yes | Yes | Chapters plus retained volume metadata where present |
| UTF-8 CSV | No | Yes | BOM, deterministic columns, quoted fields, Unicode-safe |

Native backup schema, migration, and integrity details are in
[BACKUP_SCHEMA.md](../BACKUP_SCHEMA.md).

## Strategies and matching

- **Merge safely:** add new entries and update confident matches according to
  the selected conflict policy.
- **Add only:** add new entries and leave matched local entries unchanged.
- **Replace matching:** replace confident matches while retaining unmatched
  local entries.
- **Full restore:** available only for native backups; replace the entire
  library, including with an explicitly confirmed empty backup.

Matching is deterministic in this order: exact external provider ID, exact
Unicode-aware normalized title plus media type, then a cautious similar-title
check. Similar or ambiguous titles are marked as uncertain and skipped rather
than merged automatically.

The default safe merge never lowers progress, overwrites local notes, or
flattens local per-season progress. It unions tags and provider IDs, keeps
useful dates/metadata, and accepts compatible status, score, total, synopsis,
and repeat data.

## Architecture

- `MediaTransferRepository` orchestrates provider selection, preview, safety
  backup, atomic apply, export, and history.
- `ImportProvider` and `ExportProvider` are the extension contracts.
- `ImportedMediaEntry` is the canonical provider-neutral import shape; it does
  not duplicate the stored `MediaItem` entity.
- `ImportPlanner` owns match, strategy, conflict, and merge rules.
- `NativeBackupCodec`, `MalXmlImportProvider`, `MalXmlExportProvider`, and
  `CsvExportProvider` own their formats.
- `FileTransferService` delegates to conditional Android/web platform
  adapters. Unsupported platforms return a clear error.
- `LocalStorageRepository` remains the only persistence boundary.

## Safety and limits

- Input is read as bytes; no user path is trusted or constructed by Dart.
- Native JSON is limited to 20 MB. MAL input is limited to 10 MB compressed
  and 25 MB expanded.
- MAL XML rejects document type and entity declarations before parsing.
- Native JSON and MAL files at or above 128 KB use Flutter `compute`; this is a
  background isolate on isolate-capable platforms.
- UTF-8 is primary; MAL import has an explicit ISO-8859-1 compatibility mode
  with a warning.
- Native v1 backups validate format, schema, checksum, item count, structure,
  required IDs/titles, and duplicate IDs before preview.
- Imported file contents are not copied into history. Safety backups are local,
  unencrypted JSON and may contain private notes.
- Export filenames are UTC timestamped and sanitized by the platform adapter.

## Loading, empty, error, and recovery states

The data screen shows the active validation/parsing/matching/backup/import
stage and blocks concurrent actions. Cancelling a picker is a no-op. Invalid,
unsupported, oversized, malformed, mixed MAL, unsafe XML, corrupt checksum,
future-schema, and write failures produce explicit messages without replacing
the current library. A corrupt active library is surfaced by the app shell and
is not silently replaced with sample data.

## Tests

Focused unit/widget coverage includes native round trips and migration,
checksum corruption, malformed and gzip MAL files, missing IDs and unknown
statuses, Unicode XML/CSV, title and external-ID matching, safe merge, full
restore, transaction rollback, backup retention, empty-library semantics,
history-related orchestration, picker cancellation, preview warnings, and
explicit empty restore.

## Known limitations

- MyAnimeList account/OAuth import is not enabled. It needs a registered
  client, redirect configuration, and secure token storage.
- MAL XML export includes only anime/manga entries with a known MAL/Jikan ID;
  skipped entries are reported.
- The parser builds an XML DOM after bounded byte validation. Large files are
  moved off the UI isolate, but parsing is not streaming.
- Flutter web runs `compute` on its main event loop. Size limits and preview
  row limits are enforced, but an unusually large valid web import can still
  pause rendering while JSON/XML is decoded.
- Uncertain matches are displayed and skipped; per-entry manual override is
  not yet implemented.
- Automatic safety backups and history use SharedPreferences and are not
  encrypted. The newest five backups and 25 history summaries are retained.
- iOS and desktop runner projects are absent, so their file adapters are not
  implemented.
- Live verification against MyAnimeList's official export documentation was
  blocked in the implementation environment. Compatibility is based on the
  established MAL export structure and repository fixtures; verify with a
  freshly downloaded account export before release.

## Extension instructions

Add a format by implementing `ImportProvider` and/or `ExportProvider`, mapping
through `ImportedMediaEntry`, registering the provider in
`MediaTransferRepository`, and adding malformed/empty/Unicode/large-file and
round-trip fixtures. Do not parse in widgets, write directly to
SharedPreferences, or bypass preview and safety-backup orchestration.

## Important files

- `lib/models/data_transfer.dart`
- `lib/repositories/media_transfer_repository.dart`
- `lib/repositories/local_storage_repository.dart`
- `lib/services/import_planner.dart`
- `lib/services/native_backup_service.dart`
- `lib/services/mal_xml_service.dart`
- `lib/services/csv_export_service.dart`
- `lib/services/file_transfer_*.dart`
- `lib/screens/data_management_screen.dart`
- `lib/screens/import_preview_screen.dart`
- `lib/screens/transfer_history_screen.dart`
- `android/app/src/main/kotlin/com/example/otaku_log/MainActivity.kt`
