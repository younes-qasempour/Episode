# Glossary

| Term | Accepted meaning |
| --- | --- |
| OtakuLog | The Flutter application and repository. |
| Media | The shared umbrella for anime, manga, and TV series. |
| `MediaItem` | The single shared model used by UI, API mapping, sample data, and local persistence. Do not use “media DTO” or “library item model” for a duplicate type unless a new boundary is explicitly decided. |
| Library | The locally persisted list shown on Home. “Collection” is used in profile copy, but code ownership calls this the library/media items. |
| Home | Bottom-nav tab that displays and filters the local Library. |
| Explore | Bottom-nav label for the live remote-search screen (`SearchTab`). Use “Explore” for the user-facing destination and “search” for its behavior. |
| Profile | Bottom-nav tab containing theme control and currently placeholder identity, statistics, and settings. |
| Anime | Media type string `anime`; progress unit is `Ep`. |
| Manga | Media type string `manga`; progress unit is `Ch`. |
| Series | Media type string `series`; currently means TVMaze TV series and uses `Ep`. Do not call it anime. |
| Watching | Active status used for anime/series. |
| Reading | Active status used for manga. |
| Plan to Watch | Default status for all remote results, including manga. This wording is current implementation and may need a domain decision. |
| Completed | Status automatically assigned when positive progress reaches total. |
| On Hold | Paused tracking status. |
| Jikan | Public API used for anime and manga discovery; records use MyAnimeList IDs. |
| TVMaze | Public API used for TV series discovery. |
| Seed/sample data | Eight static `MediaItem` values saved when local storage is absent, invalid, or empty. Not verified user data. |
| Stage one | **Inferred/current-task wording:** the existing functional prototype implemented before the agent bootstrap. It is not a formal release milestone in code. |
